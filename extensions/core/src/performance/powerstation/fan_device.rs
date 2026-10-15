use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use futures_util::StreamExt;
use godot::{classes::ResourceLoader, prelude::*};

use crate::{
    dbus::{
        powerstation::fan_device::{FanDeviceProxy, FanDeviceProxyBlocking},
        RunError,
    },
    get_dbus_system, get_dbus_system_blocking, RUNTIME,
};

use super::POWERSTATION_BUS;

#[derive(Debug)]
enum Signal {
    Updated,
}

/// A single PowerStation fan and its API v2 read-only state.
#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct FanDevice {
    base: Base<Resource>,
    dbus_path: String,
    proxy: Option<FanDeviceProxyBlocking<'static>>,
    rx: Receiver<Signal>,
}

#[godot_api]
impl FanDevice {
    #[signal]
    fn updated();

    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            let conn = get_dbus_system_blocking().ok();
            let (tx, rx) = channel();
            let dbus_path: String = path.clone().into();
            RUNTIME.spawn(async move {
                if let Err(error) = run(tx, dbus_path).await {
                    log::error!("Failed to run fan device task: {error:?}");
                }
            });
            let proxy = if let Some(conn) = conn.as_ref() {
                let dbus_path: String = path.clone().into();
                FanDeviceProxyBlocking::builder(conn)
                    .path(dbus_path)
                    .ok()
                    .and_then(|builder| {
                        builder
                            .cache_properties(zbus::proxy::CacheProperties::No)
                            .build()
                            .ok()
                    })
            } else {
                None
            };
            Self {
                base,
                proxy,
                dbus_path: path.into(),
                rx,
            }
        })
    }

    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{POWERSTATION_BUS}{path}");
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                return res.cast();
            }
        }
        let mut device = FanDevice::from_path(path.into());
        device.take_over_path(res_path.as_str());
        device
    }

    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.as_str().into()
    }

    #[func]
    pub fn get_id(&self) -> GString {
        self.string_property(|p| p.id())
    }

    #[func]
    pub fn get_name(&self) -> GString {
        self.string_property(|p| p.name())
    }

    #[func]
    pub fn get_mode(&self) -> GString {
        self.string_property(|p| p.mode())
    }

    #[func]
    pub fn get_fault(&self) -> GString {
        self.string_property(|p| p.fault())
    }

    #[func]
    pub fn get_percent(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.percent().ok())
            .unwrap_or_default()
            .into()
    }

    #[func]
    pub fn get_percent_valid(&self) -> bool {
        self.proxy
            .as_ref()
            .and_then(|p| p.percent_valid().ok())
            .unwrap_or(false)
    }

    #[func]
    pub fn get_available_modes(&self) -> PackedStringArray {
        self.string_array_property(|p| p.available_modes())
    }

    pub fn process(&mut self) {
        loop {
            match self.rx.try_recv() {
                Ok(Signal::Updated) => {
                    self.base_mut().emit_signal("updated", &[]);
                }
                Err(TryRecvError::Empty) => break,
                Err(TryRecvError::Disconnected) => return,
            }
        }
    }

    fn string_property<F>(&self, getter: F) -> GString
    where
        F: FnOnce(&FanDeviceProxyBlocking<'static>) -> zbus::Result<String>,
    {
        let value = self
            .proxy
            .as_ref()
            .and_then(|p| getter(p).ok())
            .unwrap_or_default();
        value.as_str().into()
    }

    fn string_array_property<F>(&self, getter: F) -> PackedStringArray
    where
        F: FnOnce(&FanDeviceProxyBlocking<'static>) -> zbus::Result<Vec<String>>,
    {
        let values: Vec<GString> = self
            .proxy
            .as_ref()
            .and_then(|p| getter(p).ok())
            .unwrap_or_default()
            .into_iter()
            .map(|value| value.as_str().into())
            .collect();
        PackedStringArray::from(values.as_slice())
    }
}

async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    let conn = get_dbus_system().await?;
    let proxy = FanDeviceProxy::builder(&conn).path(path)?.build().await?;
    // PowerStation emits Mode with every telemetry/configuration snapshot, so a
    // single stream keeps Godot updates coalesced to one event per controller tick.
    let mut changed = proxy.receive_mode_changed().await;
    while changed.next().await.is_some() {
        if tx.send(Signal::Updated).is_err() {
            break;
        }
    }
    Ok(())
}

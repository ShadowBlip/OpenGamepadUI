use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use futures_util::StreamExt;
use godot::{classes::ResourceLoader, prelude::*};

use crate::{
    dbus::{
        powerstation::connector::{ConnectorProxy, ConnectorProxyBlocking},
        RunError,
    },
    get_dbus_system, get_dbus_system_blocking, RUNTIME,
};

use super::POWERSTATION_BUS;

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Updated,
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct GpuConnector {
    base: Base<Resource>,
    dbus_path: String,
    conn: Option<zbus::blocking::Connection>,
    rx: Receiver<Signal>,

    #[allow(dead_code)]
    #[var(get = get_dpms)]
    dpms: bool,
    #[allow(dead_code)]
    #[var(get = get_enabled)]
    enabled: bool,
    #[allow(dead_code)]
    #[var(get = get_id)]
    id: u32,
    #[allow(dead_code)]
    #[var(get = get_modes)]
    modes: PackedStringArray,
    #[allow(dead_code)]
    #[var(get = get_name)]
    name: GString,
    #[allow(dead_code)]
    #[var(get = get_path)]
    path: GString,
    #[allow(dead_code)]
    #[var(get = get_status)]
    status: GString,
}

#[godot_api]
impl GpuConnector {
    /// Create a new [EventDevice] with the given DBus path
    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();
            let (tx, rx) = channel();

            // Spawn a task to listen for CPU signals
            let dbus_path = path.clone().into();
            RUNTIME.spawn(async move {
                if let Err(e) = run(tx, dbus_path).await {
                    log::error!("Failed to run CPU Core task: ${e:?}");
                }
            });

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                dbus_path: path.clone().into(),
                rx,
                dpms: Default::default(),
                path: Default::default(),
                enabled: Default::default(),
                id: Default::default(),
                modes: Default::default(),
                name: Default::default(),
                status: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the composite device
    fn get_proxy(&self) -> Option<ConnectorProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            ConnectorProxyBlocking::builder(conn)
                .path(self.dbus_path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [DBusDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{POWERSTATION_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::trace!("Resource already exists, loading that instead");
                let device: Gd<GpuConnector> = res.cast();
                device
            } else {
                let mut device = GpuConnector::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = GpuConnector::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the GPU connector instance
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone().into()
    }

    #[func]
    pub fn get_dpms(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.dpms().unwrap_or_default()
    }

    #[func]
    pub fn get_enabled(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.enabled().unwrap_or_default()
    }

    #[func]
    pub fn get_id(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.id().unwrap_or_default()
    }

    #[func]
    pub fn get_modes(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let modes = proxy.modes().unwrap_or_default();
        let modes: Vec<GString> = modes.into_iter().map(|m| m.to_godot()).collect();
        modes.into()
    }

    #[func]
    pub fn get_name(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.name().unwrap_or_default().into()
    }

    #[func]
    pub fn get_path(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.path().unwrap_or_default().into()
    }

    #[func]
    pub fn get_status(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.status().unwrap_or_default().into()
    }

    /// Dispatches signals
    pub fn process(&mut self) {
        // Drain all messages from the channel to process them
        loop {
            let signal = match self.rx.try_recv() {
                Ok(value) => value,
                Err(e) => match e {
                    TryRecvError::Empty => break,
                    TryRecvError::Disconnected => {
                        log::error!("Backend thread is not running!");
                        return;
                    }
                },
            };
            self.process_signal(signal);
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        log::trace!("Got signal: {signal:?}");
        match signal {
            Signal::Updated => {
                self.base_mut().emit_signal("updated", &[]);
            }
        }
    }
}

/// Runs GPU connector tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;
    let proxy = ConnectorProxy::builder(&conn).path(path)?.build().await?;

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_modes_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_status_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_enabled_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    Ok(())
}

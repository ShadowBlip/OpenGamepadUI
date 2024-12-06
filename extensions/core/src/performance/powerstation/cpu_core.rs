use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use futures_util::StreamExt;
use godot::{classes::ResourceLoader, prelude::*};

use crate::{
    dbus::{
        powerstation::core::{CoreProxy, CoreProxyBlocking},
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
pub struct CpuCore {
    base: Base<Resource>,
    path: String,
    conn: Option<zbus::blocking::Connection>,
    rx: Receiver<Signal>,

    #[allow(dead_code)]
    #[var(get = get_core_id)]
    core_id: u32,
    #[allow(dead_code)]
    #[var(get = get_number)]
    number: u32,
    #[allow(dead_code)]
    #[var(get = get_online, set = set_online)]
    online: bool,
}

#[godot_api]
impl CpuCore {
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
                path: path.clone().into(),
                rx,
                core_id: Default::default(),
                number: Default::default(),
                online: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the composite device
    fn get_proxy(&self) -> Option<CoreProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            CoreProxyBlocking::builder(conn)
                .path(self.path.clone())
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
                let device: Gd<CpuCore> = res.cast();
                device
            } else {
                let mut device = CpuCore::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = CpuCore::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the CPU Core instance
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.clone().into()
    }

    /// Return the core id of the CPU core
    #[func]
    pub fn get_core_id(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.core_id().unwrap_or_default()
    }

    /// Return the core number of the CPU core
    #[func]
    pub fn get_number(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.number().unwrap_or_default()
    }

    /// Return whether or not the CPU core is online
    #[func]
    pub fn get_online(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.online().unwrap_or_default()
    }

    /// Set the online status of the core to the given value
    #[func]
    pub fn set_online(&self, online: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_online(online).unwrap_or_default()
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

/// Runs CPU tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;
    let proxy = CoreProxy::builder(&conn).path(path)?.build().await?;

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_online_changed().await;
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

use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::networkmanager::active::{ActiveProxy, ActiveProxyBlocking};
use crate::dbus::RunError;
use crate::{get_dbus_system, get_dbus_system_blocking, RUNTIME};
use futures_util::stream::StreamExt;
use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use super::device::NetworkDevice;
use super::NETWORK_MANAGER_BUS;

/// Signals that can be emitted by this resource
#[derive(Debug)]
enum Signal {
    PropertyStateChanged(u32),
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct NetworkActiveConnection {
    base: Base<Resource>,

    conn: Option<zbus::blocking::Connection>,
    rx: Receiver<Signal>,
    path: String,

    /// The DBus path of the [NetworkActiveConnection]
    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    /// Array of devices which are part of this active connection
    #[allow(dead_code)]
    #[var(get = get_devices)]
    devices: Array<Gd<NetworkDevice>>,
    /// Current state of the connection
    #[allow(dead_code)]
    #[var(get = get_state)]
    state: u32,
}

#[godot_api]
impl NetworkActiveConnection {
    /// the state of the connection is unknown
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_UNKNOWN: u32 = 0;
    /// a network connection is being prepared
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_ACTIVATING: u32 = 1;
    /// there is a connection to the network
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_ACTIVATED: u32 = 2;
    /// the network connection is being torn down and cleaned up
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_DEACTIVATING: u32 = 3;
    /// the network connection is disconnected and will be removed
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_DEACTIVATED: u32 = 4;

    /// Emitted whenever the connection state changes
    #[signal]
    fn state_changed(state: u32);

    /// Create a new [NetworkActiveConnection] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Create a channel to communicate with the service
            let (tx, rx) = channel();

            // Spawn a task using the shared tokio runtime to listen for signals
            let dbus_path = path.to_string();
            RUNTIME.spawn(async move {
                if let Err(e) = run(dbus_path, tx).await {
                    log::error!("Failed to run NetworkDevice task: ${e:?}");
                }
            });

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                rx,
                path: path.clone().into(),
                dbus_path: path,
                devices: Default::default(),
                state: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the network device
    fn get_proxy(&self) -> Option<ActiveProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            ActiveProxyBlocking::builder(conn)
                .path(self.path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [NetworkActiveConnection] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{NETWORK_MANAGER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<NetworkActiveConnection> = res.cast();
                device
            } else {
                let mut device = NetworkActiveConnection::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = NetworkActiveConnection::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    /// Array of devices which are part of this active connection
    #[func]
    pub fn get_devices(&self) -> Array<Gd<NetworkDevice>> {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let paths = proxy.devices().unwrap_or_default();
        let mut devices = array![];
        for path in paths {
            let path = path.to_string();
            let device = NetworkDevice::new(path.as_str());
            devices.push(&device);
        }

        devices
    }

    /// The state of this active connection.
    #[func]
    pub fn get_state(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.state().unwrap_or_default()
    }

    /// Process signals and emit them as Godot signals.
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
        match signal {
            Signal::PropertyStateChanged(value) => {
                self.base_mut()
                    .emit_signal("state_changed", &[value.to_variant()]);
            }
        }
    }
}

/// Runs NetworkDevice tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(path: String, tx: Sender<Signal>) -> Result<(), RunError> {
    log::debug!("Spawning active connection task for {path}");
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;

    // Get a proxy instance to the device
    let connection = ActiveProxy::builder(&conn).path(path)?.build().await?;

    // Spawn a task to listen for property changes
    let mut state_changed = connection.receive_state_changed().await;
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        loop {
            tokio::select! {
                signal = state_changed.next() => {
                    let Some(signal) = signal else {
                        break;
                    };
                    let value = signal.get().await.unwrap_or_default();
                    let signal = Signal::PropertyStateChanged(value);
                    if signals_tx.send(signal).is_err() {
                        break;
                    }
                }
            }
        }
    });

    Ok(())
}

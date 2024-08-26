use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use futures_util::StreamExt;
use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::udisks2::partition::{PartitionProxy, PartitionProxyBlocking};
use crate::dbus::RunError;
use crate::{get_dbus_system, get_dbus_system_blocking, RUNTIME};

use super::UDISKS2_BUS;

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Updated,
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct PartitionDevice {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
}

#[godot_api]
impl PartitionDevice {
    #[signal]
    fn updated();

    /// Create a new [PartitionDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        godot_print!("PartitionDevice created with path: {path}");
        let (tx, rx) = channel();
        let dbus_path = path.clone().into();

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx, dbus_path).await {
                godot_error!("Failed to run PartitionDevice task: ${e:?}");
            }
        });

        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                rx,
                conn,
                dbus_path: path,
            }
        })
    }

    /// Return a proxy instance to the device
    fn get_proxy(&self) -> Option<PartitionProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            let path: String = self.dbus_path.clone().into();
            PartitionProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [PartitionDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{UDISKS2_BUS}{path}/partition");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.clone().into()) {
            if let Some(res) = resource_loader.load(res_path.clone().into()) {
                godot_print!(
                    "Resource already exists with path '{res_path}', loading that instead"
                );
                let device: Gd<PartitionDevice> = res.cast();
                device
            } else {
                let mut device = PartitionDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.into());
                device
            }
        } else {
            let mut device = PartitionDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.into());
            device
        }
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
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
                        godot_error!("Backend thread is not running!");
                        return;
                    }
                },
            };
            self.process_signal(signal);
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        godot_print!("Got signal: {signal:?}");
        match signal {
            Signal::Updated => {
                self.base_mut().emit_signal("updated".into(), &[]);
            }
        }
    }
}

impl Drop for PartitionDevice {
    fn drop(&mut self) {
        godot_print!("PartitionDevice '{}' is being destroyed!", self.dbus_path);
    }
}

/// Run the signals task
async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;
    let proxy = PartitionProxy::builder(&conn).path(path)?.build().await?;

    //let signals_tx = tx.clone();
    //let mut events = proxy.receive_connected_changed().await;
    //RUNTIME.spawn(async move {
    //    while let Some(event) = events.next().await {
    //        let value = event.get().await.unwrap_or_default();
    //        let signal = Signal::ConnectedChanged { value };
    //        if signals_tx.send(signal).is_err() {
    //            break;
    //        }
    //        let signal = Signal::Updated;
    //        if signals_tx.send(signal).is_err() {
    //            break;
    //        }
    //    }
    //});

    //let signals_tx = tx.clone();
    //let mut events = proxy.receive_paired_changed().await;
    //RUNTIME.spawn(async move {
    //    while let Some(event) = events.next().await {
    //        let value = event.get().await.unwrap_or_default();
    //        let signal = Signal::PairedChanged { value };
    //        if signals_tx.send(signal).is_err() {
    //            break;
    //        }
    //        let signal = Signal::Updated;
    //        if signals_tx.send(signal).is_err() {
    //            break;
    //        }
    //    }
    //});

    Ok(())
}

use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use futures_util::StreamExt;
use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::inputplumber::dbus_device::DBusDeviceProxy;
use crate::{get_dbus_system, RUNTIME};

use super::{RunError, INPUT_PLUMBER_BUS};

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    InputEvent {
        type_code: String,
        value: f64,
    },
    TouchEvent {
        type_code: String,
        index: u32,
        is_touching: bool,
        pressure: f64,
        x: f64,
        y: f64,
    },
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct DBusDevice {
    base: Base<Resource>,
    path: String,
    rx: Receiver<Signal>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
}

#[godot_api]
impl DBusDevice {
    #[signal]
    fn input_event(type_code: GString, value: f64);

    #[signal]
    fn touch_event(
        type_code: GString,
        index: i64,
        is_touching: bool,
        pressure: f64,
        x: f64,
        y: f64,
    );

    /// Create a new [DBusDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        log::debug!("DBusDevice created with path: {path}");
        let (tx, rx) = channel();
        let dbus_path = path.clone().into();

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx, dbus_path).await {
                log::error!("Failed to run DBusDevice task: ${e:?}");
            }
        });

        Gd::from_init_fn(|base| {
            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                path: path.clone().into(), // Convert GString -> String.
                rx,
                dbus_path: path,
            }
        })
    }

    /// Get or create a [DBusDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{INPUT_PLUMBER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<DBusDevice> = res.cast();
                device
            } else {
                let mut device = DBusDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = DBusDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.clone().into()
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
            Signal::InputEvent { type_code, value } => {
                self.base_mut().emit_signal(
                    "input_event",
                    &[type_code.to_godot().to_variant(), value.to_variant()],
                );
            }
            Signal::TouchEvent {
                type_code,
                index,
                is_touching,
                pressure,
                x,
                y,
            } => {
                self.base_mut().emit_signal(
                    "touch_event",
                    &[
                        type_code.to_godot().to_variant(),
                        index.to_variant(),
                        is_touching.to_variant(),
                        pressure.to_variant(),
                        x.to_variant(),
                        y.to_variant(),
                    ],
                );
            }
        }
    }
}

impl Drop for DBusDevice {
    fn drop(&mut self) {
        log::trace!("DBusDevice '{}' is being destroyed!", self.dbus_path);
    }
}

/// Run the signals task
async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;
    let proxy = DBusDeviceProxy::builder(&conn).path(path)?.build().await?;

    let signals_tx = tx.clone();
    let mut input_events = proxy.receive_input_event().await?;
    RUNTIME.spawn(async move {
        while let Some(event) = input_events.next().await {
            let Some(args) = event.args().ok() else {
                break;
            };
            let signal = Signal::InputEvent {
                type_code: args.event.to_string(),
                value: args.value,
            };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
        log::debug!("DBusDevice input_event task stopped");
    });

    let signals_tx = tx.clone();
    let mut touch_events = proxy.receive_touch_event().await?;
    RUNTIME.spawn(async move {
        while let Some(event) = touch_events.next().await {
            let Some(args) = event.args().ok() else {
                break;
            };
            let signal = Signal::TouchEvent {
                type_code: args.event.to_string(),
                index: args.index,
                is_touching: args.is_touching,
                pressure: args.pressure,
                x: args.x,
                y: args.y,
            };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
        log::debug!("DBusDevice touch_event task stopped");
    });

    Ok(())
}

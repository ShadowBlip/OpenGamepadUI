use std::{
    collections::HashMap,
    sync::mpsc::{channel, Receiver, Sender, TryRecvError},
    time::Duration,
};

use godot::{classes::Engine, prelude::*};
use zbus::names::BusName;

use crate::{
    dbus::{upower::UPowerProxyBlocking, RunError},
    get_dbus_system, get_dbus_system_blocking, RUNTIME,
};

use super::device::UPowerDevice;

pub const UPOWER_BUS: &str = "org.freedesktop.UPower";
const UPOWER_PATH: &str = "/org/freedesktop/UPower";
const DISPLAY_DEVICE_PATH: &str = "/org/freedesktop/UPower/devices/DisplayDevice";

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Started,
    Stopped,
}

/// UPower dbus proxy for power management
#[derive(GodotClass)]
#[class(base=Resource)]
pub struct UPowerInstance {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,
    devices: HashMap<String, Gd<UPowerDevice>>,
    #[allow(dead_code)]
    #[var(get = get_on_battery)]
    on_battery: bool,
}

#[godot_api]
impl UPowerInstance {
    /// Emitted when UPower is detected as running
    #[signal]
    fn started();

    /// Emitted when UPower is detected as stopped
    #[signal]
    fn stopped();

    /// Returns true if the UPower service is currently running
    #[func]
    fn is_running(&self) -> bool {
        let Some(conn) = self.conn.as_ref() else {
            return false;
        };
        let bus = BusName::from_static_str(UPOWER_BUS).unwrap();
        let dbus = zbus::blocking::fdo::DBusProxy::new(conn).ok();
        let Some(dbus) = dbus else {
            return false;
        };
        dbus.name_has_owner(bus.clone()).unwrap_or_default()
    }

    /// Returns whether or not the device is running on battery power
    #[func]
    pub fn get_on_battery(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return false;
        };
        proxy.on_battery().ok().unwrap_or_default()
    }

    /// Get the object to the "display device", a composite device that represents the status icon to show in desktop environments.
    #[func]
    pub fn get_display_device(&mut self) -> Gd<UPowerDevice> {
        if let Some(device) = self.devices.get(DISPLAY_DEVICE_PATH) {
            return device.clone();
        }
        let device = UPowerDevice::new(DISPLAY_DEVICE_PATH);
        self.devices
            .insert(DISPLAY_DEVICE_PATH.to_string(), device.clone());
        device
    }

    /// Process UPower signals and emit them as Godot signals. This method should be called every frame in the `_process` loop of a node.
    #[func]
    fn process(&mut self) {
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

        // Process signals for other known DBus objects
        for (_, device) in self.devices.iter_mut() {
            device.bind_mut().process();
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::Started => {
                self.base_mut().emit_signal("started", &[]);
            }
            Signal::Stopped => {
                self.base_mut().emit_signal("stopped", &[]);
            }
        }
    }

    /// Return a proxy instance to the UPower object
    fn get_proxy(&self) -> Option<UPowerProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            UPowerProxyBlocking::builder(conn)
                .path(UPOWER_PATH)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }
}

#[godot_api]
impl IResource for UPowerInstance {
    /// Called upon object initialization in the engine
    fn init(base: Base<Self::Base>) -> Self {
        log::debug!("Initializing UPower instance");

        // Create a channel to communicate with the service
        let (tx, rx) = channel();
        let conn = get_dbus_system_blocking().ok();

        // Don't run in the editor
        let engine = Engine::singleton();
        if engine.is_editor_hint() {
            return Self {
                base,
                rx,
                conn,
                devices: Default::default(),
                on_battery: Default::default(),
            };
        }

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx).await {
                log::error!("Failed to run UPower task: ${e:?}");
            }
        });

        // Create a new UPower instance
        Self {
            base,
            rx,
            conn,
            devices: HashMap::new(),
            on_battery: false,
        }
    }
}

/// Runs UPower tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>) -> Result<(), RunError> {
    log::debug!("Spawning UPower tasks");
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;

    // Spawn a task to listen for UPower start/stop
    let dbus_conn = conn.clone();
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        let bus = BusName::from_static_str(UPOWER_BUS).unwrap();
        let mut is_running = {
            let dbus = zbus::fdo::DBusProxy::new(&dbus_conn).await.ok();
            let Some(dbus) = dbus else {
                return;
            };
            dbus.name_has_owner(bus.clone()).await.unwrap_or_default()
        };

        loop {
            let dbus = zbus::fdo::DBusProxy::new(&dbus_conn).await.ok();
            let Some(dbus) = dbus else {
                break;
            };
            let running = dbus.name_has_owner(bus.clone()).await.unwrap_or_default();
            if running != is_running {
                let signal = if running {
                    Signal::Started
                } else {
                    Signal::Stopped
                };
                if signals_tx.send(signal).is_err() {
                    break;
                }
            }
            is_running = running;
            tokio::time::sleep(Duration::from_secs(5)).await;
        }
    });

    Ok(())
}

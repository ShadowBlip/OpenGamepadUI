pub mod adapter;
pub mod device;

use std::{
    collections::HashMap,
    sync::mpsc::{channel, Receiver, Sender, TryRecvError},
    time::Duration,
};

use adapter::BluetoothAdapter;
use device::BluetoothDevice;
use futures_util::stream::StreamExt;
use godot::{classes::Engine, obj::WithBaseField, prelude::*};
use zbus::fdo::ObjectManagerProxy;
use zbus::{fdo::ManagedObjects, names::BusName};

use crate::{dbus::RunError, get_dbus_system, get_dbus_system_blocking, RUNTIME};

pub const BLUEZ_BUS: &str = "org.bluez";
const BLUEZ_MANAGER_PATH: &str = "/";

/// Supported Bluez DBus objects
#[derive(Debug)]
enum ObjectType {
    Unknown,
    Adapter,
    Device,
}

impl ObjectType {
    /// Returns the object type from the list of implemented interfaces
    fn from_ifaces(ifaces: Vec<String>) -> Self {
        if ifaces.contains(&"org.bluez.Device1".to_string()) {
            Self::Device
        } else if ifaces.contains(&"org.bluez.Adapter1".to_string()) {
            Self::Adapter
        } else {
            Self::Unknown
        }
    }
}

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Started,
    Stopped,
    ObjectAdded { path: String, ifaces: Vec<String> },
    ObjectRemoved { path: String, ifaces: Vec<String> },
}

#[derive(GodotClass)]
#[class(base=Resource)]
pub struct BluezInstance {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,
    adapters: HashMap<String, Gd<BluetoothAdapter>>,
    devices: HashMap<String, Gd<BluetoothDevice>>,
}

#[godot_api]
impl BluezInstance {
    /// Emitted when Bluez is detected as running
    #[signal]
    fn started();

    /// Emitted when Bluez is detected as stopped
    #[signal]
    fn stopped();

    /// Emitted when a new bluetooth adapter is discovered
    #[signal]
    fn adapter_added(device: Gd<BluetoothAdapter>);

    /// Emitted when a bluetooth adapter is removed
    #[signal]
    fn adapter_removed(path: GString);

    /// Emitted when a new bluetooth device is discovered
    #[signal]
    fn device_added(device: Gd<BluetoothDevice>);

    /// Emitted when a bluetooth device is removed
    #[signal]
    fn device_removed(path: GString);

    /// Returns true if the Bluez service is currently running
    #[func]
    fn is_running(&self) -> bool {
        let Some(conn) = self.conn.as_ref() else {
            return false;
        };
        let bus = BusName::from_static_str(BLUEZ_BUS).unwrap();
        let dbus = zbus::blocking::fdo::DBusProxy::new(conn).ok();
        let Some(dbus) = dbus else {
            return false;
        };
        dbus.name_has_owner(bus.clone()).unwrap_or_default()
    }

    /// Get managed objects
    fn get_managed_objects(&self) -> Result<ManagedObjects, zbus::fdo::Error> {
        let Some(conn) = self.conn.as_ref() else {
            return Err(zbus::fdo::Error::Disconnected(
                "No DBus connection found".into(),
            ));
        };

        let bus = BusName::from_static_str(BLUEZ_BUS).unwrap();
        let object_manager = zbus::blocking::fdo::ObjectManagerProxy::builder(conn)
            .destination(bus)
            .ok()
            .and_then(|builder| builder.path(BLUEZ_MANAGER_PATH).ok())
            .and_then(|builder| builder.build().ok());
        let Some(object_manager) = object_manager else {
            return Ok(ManagedObjects::new());
        };

        object_manager.get_managed_objects()
    }

    /// Return a list of currently discovered bluetooth adapters
    #[func]
    fn get_adapters(&self) -> Array<Gd<BluetoothAdapter>> {
        let mut adapters = array![];
        for adapter in self.adapters.values() {
            adapters.push(adapter);
        }

        adapters
    }

    /// Return a list of currently discovered devices
    #[func]
    fn get_discovered_devices(&self) -> Array<Gd<BluetoothDevice>> {
        let mut devices = array![];
        for device in self.devices.values() {
            devices.push(device);
        }

        devices
    }

    /// Process Bluez signals and emit them as Godot signals. This method
    /// should be called every frame in the "_process" loop of a node.
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

        // Process signals on child objects
        for adapter in self.adapters.values_mut() {
            adapter.bind_mut().process();
        }
        for device in self.devices.values_mut() {
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
            Signal::ObjectAdded { path, ifaces } => {
                let obj_type = ObjectType::from_ifaces(ifaces);
                match obj_type {
                    ObjectType::Unknown => (),
                    ObjectType::Adapter => {
                        let adapter = BluetoothAdapter::new(path.as_str());
                        self.adapters.insert(path, adapter.clone());
                        self.base_mut()
                            .emit_signal("adapter_added", &[adapter.to_variant()]);
                    }
                    ObjectType::Device => {
                        let device = BluetoothDevice::new(path.as_str());
                        self.devices.insert(path, device.clone());
                        self.base_mut()
                            .emit_signal("device_added", &[device.to_variant()]);
                    }
                }
            }
            Signal::ObjectRemoved { path, ifaces } => {
                let obj_type = ObjectType::from_ifaces(ifaces);
                match obj_type {
                    ObjectType::Unknown => (),
                    ObjectType::Adapter => {
                        self.adapters.remove(&path);
                        self.base_mut()
                            .emit_signal("adapter_removed", &[path.to_variant()]);
                    }
                    ObjectType::Device => {
                        self.devices.remove(&path);
                        self.base_mut()
                            .emit_signal("device_removed", &[path.to_variant()]);
                    }
                }
            }
        }
    }
}

#[godot_api]
impl IResource for BluezInstance {
    /// Called upon object initialization in the engine
    fn init(base: Base<Self::Base>) -> Self {
        log::debug!("Initializing Bluez instance");

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
                adapters: Default::default(),
                devices: Default::default(),
            };
        }

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx).await {
                log::error!("Failed to run Bluez task: ${e:?}");
            }
        });

        // Create a new Bluez instance
        let mut instance = Self {
            base,
            rx,
            conn,
            adapters: HashMap::new(),
            devices: HashMap::new(),
        };

        // Perform initial object discovery
        let mut adapters = HashMap::new();
        let mut devices = HashMap::new();
        let objects = instance.get_managed_objects().unwrap_or_default();
        for (path, ifaces) in objects.into_iter() {
            let path = path.to_string();
            let ifaces: Vec<String> = ifaces.into_keys().map(|v| v.to_string()).collect();
            let obj_type = ObjectType::from_ifaces(ifaces);

            match obj_type {
                ObjectType::Unknown => (),
                ObjectType::Adapter => {
                    let adapter = BluetoothAdapter::new(path.as_str());
                    adapters.insert(path, adapter);
                }
                ObjectType::Device => {
                    let device = BluetoothDevice::new(path.as_str());
                    devices.insert(path, device);
                }
            }
        }

        // Update the discovered objects
        instance.adapters = adapters;
        instance.devices = devices;

        instance
    }
}

/// Runs Bluez tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>) -> Result<(), RunError> {
    log::debug!("Spawning Bluez tasks");
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;

    // Spawn a task to listen for Bluez start/stop
    let dbus_conn = conn.clone();
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        let bus = BusName::from_static_str(BLUEZ_BUS).unwrap();
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

    // Get a proxy instance to ObjectManager
    let bus = BusName::from_static_str(BLUEZ_BUS).unwrap();
    let object_manager: ObjectManagerProxy = ObjectManagerProxy::builder(&conn)
        .destination(bus)?
        .path(BLUEZ_MANAGER_PATH)?
        .build()
        .await?;

    // Spawn a task to listen for objects added
    let mut ifaces_added = object_manager.receive_interfaces_added().await?;
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        while let Some(signal) = ifaces_added.next().await {
            let args = match signal.args() {
                Ok(args) => args,
                Err(e) => {
                    log::warn!("Failed to get signal args: ${e:?}");
                    continue;
                }
            };

            let path = args.object_path.to_string();
            let ifaces = args
                .interfaces_and_properties
                .keys()
                .map(|v| v.to_string())
                .collect();
            let signal = Signal::ObjectAdded { path, ifaces };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    // Spawn a task to listen for objects removed
    let mut ifaces_removed = object_manager.receive_interfaces_removed().await?;
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        while let Some(signal) = ifaces_removed.next().await {
            let args = match signal.args() {
                Ok(args) => args,
                Err(e) => {
                    log::warn!("Failed to get signal args: ${e:?}");
                    continue;
                }
            };

            let path = args.object_path.to_string();
            let ifaces = args.interfaces.iter().map(|v| v.to_string()).collect();
            let signal = Signal::ObjectRemoved { path, ifaces };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    Ok(())
}

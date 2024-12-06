pub mod access_point;
pub mod active_connection;
pub mod device;
pub mod device_wireless;
pub mod ip4_config;

use crate::{
    dbus::{networkmanager::network_manager::NetworkManagerProxyBlocking, RunError},
    get_dbus_system, get_dbus_system_blocking, RUNTIME,
};
use access_point::NetworkAccessPoint;
use device::NetworkDevice;
use device_wireless::NetworkDeviceWireless;
use futures_util::stream::StreamExt;
use ip4_config::NetworkIpv4Config;
use std::{
    collections::HashMap,
    sync::mpsc::{channel, Receiver, Sender, TryRecvError},
    time::Duration,
};
use zbus::fdo::{ManagedObjects, ObjectManagerProxy};

use godot::{classes::Engine, prelude::*};
use zbus::names::BusName;

const NETWORK_MANAGER_BUS: &str = "org.freedesktop.NetworkManager";
const OBJECT_MANAGER_PATH: &str = "/org/freedesktop";

/// Supported NetworkManager DBus objects
#[derive(Debug)]
enum ObjectType {
    Unknown,
    AccessPoint,
    AgentManager,
    ConnectionActive,
    Device,
    DeviceBluetooth,
    DeviceGeneric,
    DeviceWired,
    DeviceWireless,
    Dhcp4Config,
    Dhcp6Config,
    Ip4Config,
    Ip6Config,
    Settings,
    SettingsConnection,
}

impl ObjectType {
    /// Returns the object type(s) from the list of implemented interfaces
    fn from_ifaces(ifaces: Vec<String>) -> Vec<Self> {
        let types = ifaces
            .into_iter()
            .map(|iface| match iface.as_str() {
                "org.freedesktop.NetworkManager.AccessPoint" => Self::AccessPoint,
                "org.freedesktop.NetworkManager.AgentManager" => Self::AgentManager,
                "org.freedesktop.NetworkManager.Connection.Active" => Self::ConnectionActive,
                "org.freedesktop.NetworkManager.Device" => Self::Device,
                "org.freedesktop.NetworkManager.Device.Bluetooth" => Self::DeviceBluetooth,
                "org.freedesktop.NetworkManager.Device.Generic" => Self::DeviceGeneric,
                "org.freedesktop.NetworkManager.Device.Wired" => Self::DeviceWired,
                "org.freedesktop.NetworkManager.Device.Wireless" => Self::DeviceWireless,
                "org.freedesktop.NetworkManager.DHCP4Config" => Self::Dhcp4Config,
                "org.freedesktop.NetworkManager.DHCP6Config" => Self::Dhcp6Config,
                "org.freedesktop.NetworkManager.IP4Config" => Self::Ip4Config,
                "org.freedesktop.NetworkManager.IP6Config" => Self::Ip6Config,
                "org.freedesktop.NetworkManager.Settings" => Self::Settings,
                "org.freedesktop.NetworkManager.Settings.Connection" => Self::SettingsConnection,
                _ => Self::Unknown,
            })
            .collect();

        types
    }
}

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Started,
    Stopped,
    ObjectAdded {
        path: String,
        ifaces: Vec<ObjectType>,
    },
    ObjectRemoved {
        path: String,
        ifaces: Vec<ObjectType>,
    },
}

#[derive(GodotClass)]
#[class(base=Resource)]
pub struct NetworkManagerInstance {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,
    access_points: HashMap<String, Gd<NetworkAccessPoint>>,
    devices: HashMap<String, Gd<NetworkDevice>>,
    devices_wireless: HashMap<String, Gd<NetworkDeviceWireless>>,
    ipv4_configs: HashMap<String, Gd<NetworkIpv4Config>>,

    /// Current connectivity status
    #[allow(dead_code)]
    #[var(get = get_connectivity)]
    connectivity: i32,
}

#[godot_api]
impl NetworkManagerInstance {
    /// Network connectivity is unknown.
    #[constant]
    const NM_CONNECTIVITY_UNKNOWN: i32 = 1;
    /// The host is not connected to any network.
    #[constant]
    const NM_CONNECTIVITY_NONE: i32 = 2;
    /// The host is behind a captive portal and cannot reach the full Internet.
    #[constant]
    const NM_CONNECTIVITY_PORTAL: i32 = 3;
    /// The host is connected to a network, but does not appear to be able to reach the full Internet.
    #[constant]
    const NM_CONNECTIVITY_LIMITED: i32 = 4;
    /// The host is connected to a network, and appears to be able to reach the full Internet.
    #[constant]
    const NM_CONNECTIVITY_FULL: i32 = 5;

    /// Emitted when NetworkManager is detected as running
    #[signal]
    fn started();

    /// Emitted when NetworkManager is detected as stopped
    #[signal]
    fn stopped();

    /// Return a proxy instance to the NetworkManager
    fn get_proxy(&self) -> Option<NetworkManagerProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            NetworkManagerProxyBlocking::builder(conn).build().ok()
        } else {
            None
        }
    }

    /// Returns true if the NetworkManager service is currently running
    #[func]
    pub fn is_running(&self) -> bool {
        let Some(conn) = self.conn.as_ref() else {
            return false;
        };
        let bus = BusName::from_static_str(NETWORK_MANAGER_BUS).unwrap();
        let dbus = zbus::blocking::fdo::DBusProxy::new(conn).ok();
        let Some(dbus) = dbus else {
            return false;
        };
        dbus.name_has_owner(bus.clone()).unwrap_or_default()
    }

    /// The network connectivity state.
    #[func]
    pub fn get_connectivity(&self) -> i32 {
        let Some(proxy) = self.get_proxy() else {
            return NetworkManagerInstance::NM_CONNECTIVITY_UNKNOWN;
        };
        let value = proxy
            .connectivity()
            .ok()
            .unwrap_or(NetworkManagerInstance::NM_CONNECTIVITY_UNKNOWN as u32);
        value as i32
    }

    /// Returns an array of all network devices
    #[func]
    pub fn get_devices(&self) -> Array<Gd<NetworkDevice>> {
        let mut devices = array![];
        for device in self.devices.values() {
            devices.push(device);
        }

        devices
    }

    /// Returns a HashMap of all the objects managed by this dbus interface
    fn get_managed_objects(&self) -> Result<ManagedObjects, zbus::fdo::Error> {
        let Some(conn) = self.conn.as_ref() else {
            return Err(zbus::fdo::Error::Disconnected(
                "No DBus connection found".into(),
            ));
        };

        let bus = BusName::from_static_str(NETWORK_MANAGER_BUS).unwrap();
        let object_manager = zbus::blocking::fdo::ObjectManagerProxy::builder(conn)
            .destination(bus)
            .ok()
            .and_then(|builder| builder.path(OBJECT_MANAGER_PATH).ok())
            .and_then(|builder| builder.build().ok());
        let Some(object_manager) = object_manager else {
            return Ok(ManagedObjects::new());
        };

        object_manager.get_managed_objects()
    }

    /// Process NetworkManager signals and emit them as Godot signals. This method
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

        // Process signals from tracked devices
        //for (_, device) in self.dbus_devices.iter_mut() {
        //    device.bind_mut().process();
        //}
        //for (_, device) in self.composite_devices.iter_mut() {
        //    device.bind_mut().process();
        //}
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::Started => {
                self.base_mut().emit_signal("started", &[]);
            }
            Signal::Stopped => {
                // Clear all known devices
                self.devices.clear();
                self.base_mut().emit_signal("stopped", &[]);
            }
            Signal::ObjectAdded { path, ifaces } => {
                self.on_object_added(path.as_str(), ifaces);
            }
            Signal::ObjectRemoved { path, ifaces } => {
                self.on_object_removed(path.as_str(), ifaces);
            }
        }
    }

    /// Track the given object and emit signals
    fn on_object_added(&mut self, path: &str, types: Vec<ObjectType>) {
        for iface in types {
            match iface {
                ObjectType::Unknown => (),
                ObjectType::AccessPoint => {
                    let ap = NetworkAccessPoint::new(path);
                    self.access_points.insert(path.to_string(), ap.clone());
                }
                ObjectType::AgentManager => (),
                ObjectType::ConnectionActive => (),
                ObjectType::Device => {
                    let device = NetworkDevice::new(path);
                    self.devices.insert(path.to_string(), device.clone());
                }
                ObjectType::DeviceBluetooth => (),
                ObjectType::DeviceGeneric => (),
                ObjectType::DeviceWired => (),
                ObjectType::DeviceWireless => {
                    let device = NetworkDeviceWireless::new(path);
                    self.devices_wireless
                        .insert(path.to_string(), device.clone());
                }
                ObjectType::Dhcp4Config => (),
                ObjectType::Dhcp6Config => (),
                ObjectType::Ip4Config => {
                    let config = NetworkIpv4Config::new(path);
                    self.ipv4_configs.insert(path.to_string(), config.clone());
                }
                ObjectType::Ip6Config => (),
                ObjectType::Settings => (),
                ObjectType::SettingsConnection => (),
            }
        }
    }

    /// Remove the given object and emit signals
    fn on_object_removed(&mut self, path: &str, types: Vec<ObjectType>) {
        for iface in types {
            match iface {
                ObjectType::Unknown => (),
                ObjectType::AccessPoint => {
                    self.access_points.remove(path);
                }
                ObjectType::AgentManager => (),
                ObjectType::ConnectionActive => (),
                ObjectType::Device => {
                    self.devices.remove(path);
                }
                ObjectType::DeviceBluetooth => (),
                ObjectType::DeviceGeneric => (),
                ObjectType::DeviceWired => (),
                ObjectType::DeviceWireless => {
                    self.devices_wireless.remove(path);
                }
                ObjectType::Dhcp4Config => (),
                ObjectType::Dhcp6Config => (),
                ObjectType::Ip4Config => {
                    self.ipv4_configs.remove(path);
                }
                ObjectType::Ip6Config => (),
                ObjectType::Settings => (),
                ObjectType::SettingsConnection => (),
            }
        }
    }
}

#[godot_api]
impl IResource for NetworkManagerInstance {
    /// Called upon object initialization in the engine
    fn init(base: Base<Self::Base>) -> Self {
        log::debug!("Initializing NetworkManager instance");

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
                connectivity: NetworkManagerInstance::NM_CONNECTIVITY_UNKNOWN,
                access_points: Default::default(),
                devices: Default::default(),
                devices_wireless: Default::default(),
                ipv4_configs: Default::default(),
            };
        }

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx).await {
                log::error!("Failed to run NetworkManager task: ${e:?}");
            }
        });

        // Create a new NetworkManager instance
        let mut instance = Self {
            base,
            rx,
            conn,
            connectivity: NetworkManagerInstance::NM_CONNECTIVITY_UNKNOWN,
            access_points: Default::default(),
            devices: Default::default(),
            devices_wireless: Default::default(),
            ipv4_configs: Default::default(),
        };
        if !instance.is_running() {
            return instance;
        }

        // Do initial object discovery
        let objects = instance.get_managed_objects().unwrap_or_default();
        for (path, ifaces) in objects.into_iter() {
            let path = path.to_string();
            let ifaces: Vec<String> = ifaces.into_keys().map(|v| v.to_string()).collect();
            let obj_types = ObjectType::from_ifaces(ifaces);
            instance.on_object_added(path.as_str(), obj_types);
        }

        instance
    }
}

/// Runs NetworkManager tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>) -> Result<(), RunError> {
    log::debug!("Spawning networkmanager");
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;

    // Spawn a task to listen for NetworkManager start/stop
    let dbus_conn = conn.clone();
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        let bus = BusName::from_static_str(NETWORK_MANAGER_BUS).unwrap();
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
    let bus = BusName::from_static_str(NETWORK_MANAGER_BUS).unwrap();
    let object_manager: ObjectManagerProxy = ObjectManagerProxy::builder(&conn)
        .destination(bus)?
        .path(OBJECT_MANAGER_PATH)?
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
            let ifaces = ObjectType::from_ifaces(ifaces);
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
            let ifaces = ObjectType::from_ifaces(ifaces);
            let signal = Signal::ObjectRemoved { path, ifaces };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    Ok(())
}

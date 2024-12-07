pub mod access_point;
pub mod active_connection;
pub mod device;
pub mod device_wireless;
pub mod ip4_config;

use crate::{
    dbus::{
        networkmanager::network_manager::{NetworkManagerProxy, NetworkManagerProxyBlocking},
        RunError,
    },
    get_dbus_system, get_dbus_system_blocking, RUNTIME,
};
use access_point::NetworkAccessPoint;
use active_connection::NetworkActiveConnection;
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

use godot::{classes::Engine, obj::WithBaseField, prelude::*};
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
    PropertyStateChanged(u32),
    PropertyConnectivityChanged(u32),
    PropertyPrimaryConnectionChanged(String),
}

#[derive(GodotClass)]
#[class(base=Resource)]
pub struct NetworkManagerInstance {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,
    active_connections: HashMap<String, Gd<NetworkActiveConnection>>,
    access_points: HashMap<String, Gd<NetworkAccessPoint>>,
    devices: HashMap<String, Gd<NetworkDevice>>,
    devices_wireless: HashMap<String, Gd<NetworkDeviceWireless>>,
    ipv4_configs: HashMap<String, Gd<NetworkIpv4Config>>,

    /// Current connectivity status
    #[allow(dead_code)]
    #[var(get = get_connectivity)]
    connectivity: i32,
    /// The primary active connection being used to access the network
    #[allow(dead_code)]
    #[var(get = get_primary_connection)]
    primary_connection: Option<Gd<NetworkActiveConnection>>,
    /// The network connectivity state
    #[allow(dead_code)]
    #[var(get = get_state)]
    state: u32,
    /// Indicates if wireless is enabled or not
    #[allow(dead_code)]
    #[var(get = get_wireless_enabled, set = set_wireless_enabled)]
    wireless_enabled: bool,
}

#[godot_api]
impl NetworkManagerInstance {
    /// networking state is unknown
    #[constant]
    const NM_STATE_UNKNOWN: u32 = 0;
    /// networking is not enabled
    #[constant]
    const NM_STATE_ASLEEP: u32 = 10;
    /// there is no active network connection
    #[constant]
    const NM_STATE_DISCONNECTED: u32 = 20;
    /// network connections are being cleaned up
    #[constant]
    const NM_STATE_DISCONNECTING: u32 = 30;
    /// a network connection is being started
    #[constant]
    const NM_STATE_CONNECTING: u32 = 40;
    /// there is only local IPv4 and/or IPv6 connectivity
    #[constant]
    const NM_STATE_CONNECTED_LOCAL: u32 = 50;
    /// there is only site-wide IPv4 and/or IPv6 connectivity
    #[constant]
    const NM_STATE_CONNECTED_SITE: u32 = 60;
    /// there is global IPv4 and/or IPv6 Internet connectivity
    #[constant]
    const NM_STATE_CONNECTED_GLOBAL: u32 = 70;

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

    /// Emitted when the network state changes
    #[signal]
    fn state_changed(state: u32);

    /// Emitted when network connectivity changes
    #[signal]
    fn connectivity_changed(connectivity: u32);

    /// Emitted when the primary connection changes
    #[signal]
    fn primary_connection_changed(connection: Option<Gd<NetworkActiveConnection>>);

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

    /// The network connectivity state
    #[func]
    pub fn get_state(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return NetworkManagerInstance::NM_STATE_UNKNOWN;
        };
        proxy.state().unwrap_or_default()
    }

    /// Indicates if wireless is currently enabled or not
    #[func]
    pub fn get_wireless_enabled(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.wireless_enabled().unwrap_or_default()
    }

    /// Set whether wireless networking should be enabled
    #[func]
    pub fn set_wireless_enabled(&self, value: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_wireless_enabled(value).unwrap_or_default()
    }

    /// The primary active connection being used to access the network
    #[func]
    pub fn get_primary_connection(&self) -> Option<Gd<NetworkActiveConnection>> {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let path = proxy.primary_connection().unwrap_or_default();
        if path.is_empty() || path.as_str() == "/" {
            return None;
        }
        let path = path.to_string();
        self.active_connections.get(&path).cloned()
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

        // Process signals from tracked objects
        for (_, device) in self.devices.iter_mut() {
            device.bind_mut().process();
        }
        for (_, device) in self.devices_wireless.iter_mut() {
            device.bind_mut().process();
        }
        for (_, connection) in self.active_connections.iter_mut() {
            connection.bind_mut().process();
        }
        for (_, ap) in self.access_points.iter_mut() {
            ap.bind_mut().process();
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::Started => {
                self.base_mut().emit_signal("started", &[]);
            }
            Signal::Stopped => {
                self.devices.clear();
                self.base_mut().emit_signal("stopped", &[]);
            }
            Signal::ObjectAdded { path, ifaces } => {
                self.on_object_added(path.as_str(), ifaces);
            }
            Signal::ObjectRemoved { path, ifaces } => {
                self.on_object_removed(path.as_str(), ifaces);
            }
            Signal::PropertyStateChanged(value) => {
                self.base_mut()
                    .emit_signal("state_changed", &[value.to_variant()]);
            }
            Signal::PropertyConnectivityChanged(value) => {
                self.base_mut()
                    .emit_signal("connectivity_changed", &[value.to_variant()]);
            }
            Signal::PropertyPrimaryConnectionChanged(path) => {
                let conn = if path.is_empty() || path.as_str() == "/" {
                    None
                } else {
                    Some(NetworkActiveConnection::new(path.as_str()))
                };
                self.base_mut()
                    .emit_signal("primary_connection_changed", &[conn.to_variant()]);
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
                ObjectType::ConnectionActive => {
                    let connection = NetworkActiveConnection::new(path);
                    self.active_connections
                        .insert(path.to_string(), connection.clone());
                }
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
                ObjectType::ConnectionActive => {
                    self.active_connections.remove(path);
                }
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
                active_connections: Default::default(),
                access_points: Default::default(),
                devices: Default::default(),
                devices_wireless: Default::default(),
                ipv4_configs: Default::default(),
                state: Default::default(),
                wireless_enabled: Default::default(),
                primary_connection: Default::default(),
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
            active_connections: Default::default(),
            access_points: Default::default(),
            devices: Default::default(),
            devices_wireless: Default::default(),
            ipv4_configs: Default::default(),
            state: Default::default(),
            wireless_enabled: Default::default(),
            primary_connection: Default::default(),
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

    // Spawn a task to listen for objects added/removed
    let mut ifaces_added = object_manager.receive_interfaces_added().await?;
    let mut ifaces_removed = object_manager.receive_interfaces_removed().await?;
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        loop {
            tokio::select! {
                signal = ifaces_added.next() => {
                    let Some(signal) = signal else {
                        break;
                    };
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
                signal = ifaces_removed.next() => {
                    let Some(signal) = signal else {
                        break;
                    };
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
            }
        }
    });

    // Get a proxy instance to Networkmanager
    let network_manager = NetworkManagerProxy::builder(&conn).build().await?;

    // Spawn a task for property changes
    let mut state_changed = network_manager.receive_state_changed().await;
    let mut connectivity_changed = network_manager.receive_connectivity_changed().await;
    let mut primary_changed = network_manager.receive_primary_connection_changed().await;
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
                signal = connectivity_changed.next() => {
                    let Some(signal) = signal else {
                        break;
                    };
                    let value = signal.get().await.unwrap_or_default();
                    let signal = Signal::PropertyConnectivityChanged(value);
                    if signals_tx.send(signal).is_err() {
                        break;
                    }
                }
                signal = primary_changed.next() => {
                    let Some(signal) = signal else {
                        break;
                    };
                    let value = signal.get().await.unwrap_or_default().to_string();
                    let signal = Signal::PropertyPrimaryConnectionChanged(value);
                    if signals_tx.send(signal).is_err() {
                        break;
                    }
                }
            }
        }
    });

    Ok(())
}

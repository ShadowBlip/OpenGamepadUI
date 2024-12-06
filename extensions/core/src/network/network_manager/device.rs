use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::networkmanager::device::DeviceProxyBlocking;
use crate::get_dbus_system_blocking;

use super::device_wireless::NetworkDeviceWireless;
use super::ip4_config::NetworkIpv4Config;
use super::NETWORK_MANAGER_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct NetworkDevice {
    base: Base<Resource>,

    conn: Option<zbus::blocking::Connection>,
    path: String,

    /// The DBus path of the [NetworkDevice]
    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    /// The general type of the network device; ie Ethernet, WiFi, etc.
    #[allow(dead_code)]
    #[var(get = get_device_type)]
    device_type: i32,
    /// The [NetworkIpv4Config] describing the configuration of the device. Null if device has no IP.
    #[allow(dead_code)]
    #[var(get = get_ip4_config)]
    ip4_config: Option<Gd<NetworkIpv4Config>>,
    /// The name of the device's control (and often data) interface. Note that non UTF-8 characters are backslash escaped, so the resulting name may be longer then 15 characters. Use g_strcompress() to revert the escaping.
    #[allow(dead_code)]
    #[var(get = get_interface)]
    interface: GString,
    /// The [NetworkDeviceWireless] for the device. Will be null if this is not a wireless device
    #[allow(dead_code)]
    #[var(get = get_wireless)]
    wireless: Option<Gd<NetworkDeviceWireless>>,
}

#[godot_api]
impl NetworkDevice {
    /// unknown device
    #[constant]
    const NM_DEVICE_TYPE_UNKNOWN: i32 = 0;
    /// generic support for unrecognized device types
    #[constant]
    const NM_DEVICE_TYPE_GENERIC: i32 = 14;
    /// a wired ethernet device
    #[constant]
    const NM_DEVICE_TYPE_ETHERNET: i32 = 1;
    /// an 802.11 WiFi device
    #[constant]
    const NM_DEVICE_TYPE_WIFI: i32 = 2;
    /// not used
    #[constant]
    const NM_DEVICE_TYPE_UNUSED1: i32 = 3;
    /// not used
    #[constant]
    const NM_DEVICE_TYPE_UNUSED2: i32 = 4;
    /// a Bluetooth device supporting PAN or DUN access protocols
    #[constant]
    const NM_DEVICE_TYPE_BT: i32 = 5;
    /// an OLPC XO mesh networking device
    #[constant]
    const NM_DEVICE_TYPE_OLPC_MESH: i32 = 6;
    /// an 802.16e Mobile WiMAX broadband device
    #[constant]
    const NM_DEVICE_TYPE_WIMAX: i32 = 7;
    /// a modem supporting analog telephone, CDMA/EVDO, GSM/UMTS, or LTE network access protocols
    #[constant]
    const NM_DEVICE_TYPE_MODEM: i32 = 8;
    /// an IP-over-InfiniBand device
    #[constant]
    const NM_DEVICE_TYPE_INFINIBAND: i32 = 9;
    /// a bond master interface
    #[constant]
    const NM_DEVICE_TYPE_BOND: i32 = 10;
    /// an 802.1Q VLAN interface
    #[constant]
    const NM_DEVICE_TYPE_VLAN: i32 = 11;
    /// ADSL modem
    #[constant]
    const NM_DEVICE_TYPE_ADSL: i32 = 12;
    /// a bridge master interface
    #[constant]
    const NM_DEVICE_TYPE_BRIDGE: i32 = 13;
    /// a team master interface
    #[constant]
    const NM_DEVICE_TYPE_TEAM: i32 = 15;
    /// a TUN or TAP interface
    #[constant]
    const NM_DEVICE_TYPE_TUN: i32 = 16;
    /// a IP tunnel interface
    #[constant]
    const NM_DEVICE_TYPE_IP_TUNNEL: i32 = 17;
    /// a MACVLAN interface
    #[constant]
    const NM_DEVICE_TYPE_MACVLAN: i32 = 18;
    /// a VXLAN interface
    #[constant]
    const NM_DEVICE_TYPE_VXLAN: i32 = 19;
    /// a VETH interface
    #[constant]
    const NM_DEVICE_TYPE_VETH: i32 = 20;

    /// the device's state is unknown
    #[constant]
    const NM_DEVICE_STATE_UNKNOWN: i32 = 0;
    /// the device is recognized, but not managed by NetworkManager
    #[constant]
    const NM_DEVICE_STATE_UNMANAGED: i32 = 10;
    /// the device is managed by NetworkManager, but is not available for use. Reasons may include the wireless switched off, missing firmware, no ethernet carrier, missing supplicant or modem manager, etc.
    #[constant]
    const NM_DEVICE_STATE_UNAVAILABLE: i32 = 20;
    /// the device can be activated, but is currently idle and not connected to a network.
    #[constant]
    const NM_DEVICE_STATE_DISCONNECTED: i32 = 30;
    /// the device is preparing the connection to the network. This may include operations like changing the MAC address, setting physical link properties, and anything else required to connect to the requested network.
    #[constant]
    const NM_DEVICE_STATE_PREPARE: i32 = 40;
    /// the device is connecting to the requested network. This may include operations like associating with the WiFi AP, dialing the modem, connecting to the remote Bluetooth device, etc.
    #[constant]
    const NM_DEVICE_STATE_CONFIG: i32 = 50;
    /// the device requires more information to continue connecting to the requested network. This includes secrets like WiFi passphrases, login passwords, PIN codes, etc.
    #[constant]
    const NM_DEVICE_STATE_NEED_AUTH: i32 = 60;
    /// the device is requesting IPv4 and/or IPv6 addresses and routing information from the network.
    #[constant]
    const NM_DEVICE_STATE_IP_CONFIG: i32 = 70;
    /// the device is checking whether further action is required for the requested network connection. This may include checking whether only local network access is available, whether a captive portal is blocking access to the Internet, etc.
    #[constant]
    const NM_DEVICE_STATE_IP_CHECK: i32 = 80;
    /// the device is waiting for a secondary connection (like a VPN) which must activated before the device can be activated
    #[constant]
    const NM_DEVICE_STATE_SECONDARIES: i32 = 90;
    /// the device has a network connection, either local or global.
    #[constant]
    const NM_DEVICE_STATE_ACTIVATED: i32 = 100;
    /// a disconnection from the current network connection was requested, and the device is cleaning up resources used for that connection. The network connection may still be valid.
    #[constant]
    const NM_DEVICE_STATE_DEACTIVATING: i32 = 110;
    /// the device failed to connect to the requested network and is cleaning up the connection request
    #[constant]
    const NM_DEVICE_STATE_FAILED: i32 = 120;

    /// Create a new [NetworkDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                path: path.clone().into(), // Convert GString -> String.
                dbus_path: path,
                device_type: Default::default(),
                wireless: Default::default(),
                ip4_config: Default::default(),
                interface: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the network device
    fn get_proxy(&self) -> Option<DeviceProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            DeviceProxyBlocking::builder(conn)
                .path(self.path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [NetworkDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{NETWORK_MANAGER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<NetworkDevice> = res.cast();
                device
            } else {
                let mut device = NetworkDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = NetworkDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    /// The general type of the network device; ie Ethernet, WiFi, etc.
    #[func]
    pub fn get_device_type(&self) -> i32 {
        let Some(proxy) = self.get_proxy() else {
            return NetworkDevice::NM_DEVICE_TYPE_UNKNOWN;
        };
        let value = proxy
            .device_type()
            .unwrap_or(NetworkDevice::NM_DEVICE_TYPE_UNKNOWN as u32);
        value as i32
    }

    /// The name of the device's control (and often data) interface. Note that non UTF-8 characters are backslash escaped, so the resulting name may be longer then 15 characters. Use g_strcompress() to revert the escaping.
    #[func]
    pub fn get_interface(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.interface().unwrap_or_default().into()
    }

    /// The [NetworkIpv4Config] describing the configuration of the device. Null if device has no IP.
    #[func]
    pub fn get_ip4_config(&self) -> Option<Gd<NetworkIpv4Config>> {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let path = proxy.ip4_config().unwrap_or_default();
        let res_path = format!("dbus://{NETWORK_MANAGER_BUS}{path}");

        // Check to see if a resource exists
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            return Some(NetworkIpv4Config::new(path.as_str()));
        }

        None
    }

    /// Gets the wireless interface for this device. Returns null if this is not a wireless device.
    #[func]
    pub fn get_wireless(&self) -> Option<Gd<NetworkDeviceWireless>> {
        let res_path = format!("dbus://{NETWORK_MANAGER_BUS}{}/wireless", self.dbus_path);

        // Check to see if a resource exists
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            return Some(NetworkDeviceWireless::new(
                self.dbus_path.to_string().as_str(),
            ));
        }

        None
    }

    /// Dispatches signals
    pub fn process(&mut self) {}
}

use std::collections::HashMap;

use godot::prelude::*;

use godot::classes::{ProjectSettings, Resource, ResourceLoader};

use crate::dbus::networkmanager::wireless::WirelessProxyBlocking;
use crate::dbus::DBusVariant;
use crate::get_dbus_system_blocking;

use super::access_point::NetworkAccessPoint;
use super::NETWORK_MANAGER_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct NetworkDeviceWireless {
    base: Base<Resource>,

    conn: Option<zbus::blocking::Connection>,
    path: String,

    /// The DBus path of the [NetworkDeviceWireless]
    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    /// List of access point visible to this wireless device.
    #[allow(dead_code)]
    #[var(get = get_access_points)]
    access_points: Array<Gd<NetworkAccessPoint>>,
    /// The access point currently used by the wireless device. Null if no active access point.
    #[allow(dead_code)]
    #[var(get = get_active_access_point)]
    active_access_point: Option<Gd<NetworkAccessPoint>>,
    /// The bit rate currently used by the wireless device, in kilobits/second (Kb/s).
    #[allow(dead_code)]
    #[var(get = get_bitrate)]
    bitrate: u32,
    /// The active hardware address of the device.
    #[allow(dead_code)]
    #[var(get = get_hardware_address)]
    hardware_address: GString,
}

#[godot_api]
impl NetworkDeviceWireless {
    /// Create a new [NetworkDeviceWireless] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                path: path.clone().into(),
                dbus_path: path,
                hardware_address: Default::default(),
                access_points: Default::default(),
                active_access_point: Default::default(),
                bitrate: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the network device
    fn get_proxy(&self) -> Option<WirelessProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            WirelessProxyBlocking::builder(conn)
                .path(self.path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [NetworkDeviceWireless] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{NETWORK_MANAGER_BUS}{path}/wireless");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<NetworkDeviceWireless> = res.cast();
                device
            } else {
                let mut device = NetworkDeviceWireless::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = NetworkDeviceWireless::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    /// The bit rate currently used by the wireless device, in kilobits/second (Kb/s).
    #[func]
    pub fn get_bitrate(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.bitrate().unwrap_or_default()
    }

    /// List of access point visible to this wireless device.
    #[func]
    pub fn get_access_points(&self) -> Array<Gd<NetworkAccessPoint>> {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let mut resource_loader = ResourceLoader::singleton();
        let mut value = array![];
        let aps = proxy.get_access_points().unwrap_or_default();
        for ap in aps {
            let res_path = format!("dbus://{NETWORK_MANAGER_BUS}/{ap}");

            // Check to see if the resource exists
            if resource_loader.exists(res_path.as_str()) {
                let access_point = NetworkAccessPoint::new(ap.as_str());
                value.push(&access_point);
            }
        }

        value
    }

    /// The access point currently used by the wireless device. Null if no active access point.
    #[func]
    pub fn get_active_access_point(&self) -> Option<Gd<NetworkAccessPoint>> {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let ap = proxy.active_access_point().unwrap_or_default();
        if ap.is_empty() {
            return None;
        }

        let mut resource_loader = ResourceLoader::singleton();
        let res_path = format!("dbus://{NETWORK_MANAGER_BUS}/{ap}");

        // Check to see if the resource exists
        if resource_loader.exists(res_path.as_str()) {
            let access_point = NetworkAccessPoint::new(ap.as_str());
            return Some(access_point);
        }

        None
    }

    /// Request the device to scan
    #[func]
    pub fn request_scan(&self) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        proxy.request_scan(HashMap::new()).unwrap_or_default()
    }

    /// The active hardware address of the device.
    #[func]
    pub fn get_hardware_address(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.hw_address().unwrap_or_default().into()
    }

    /// Dispatches signals
    pub fn process(&mut self) {}
}

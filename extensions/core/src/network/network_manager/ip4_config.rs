use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::networkmanager::ip4config::IP4ConfigProxyBlocking;
use crate::dbus::GodotVariant;
use crate::get_dbus_system_blocking;

use super::NETWORK_MANAGER_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct NetworkIpv4Config {
    base: Base<Resource>,

    conn: Option<zbus::blocking::Connection>,
    path: String,

    /// The DBus path of the [NetworkIpv4Config]
    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    /// Array of IP address data objects. All addresses will include "address" (an IP address string), and "prefix" (a uint). Some addresses may include additional attributes.
    #[allow(dead_code)]
    #[var(get = get_addresses)]
    addresses: Array<Dictionary>,
    /// The gateway in use.
    #[allow(dead_code)]
    #[var(get = get_gateway)]
    gateway: GString,
}

#[godot_api]
impl NetworkIpv4Config {
    /// Create a new [NetworkIpv4Config] with the given DBus path
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
                addresses: Default::default(),
                gateway: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the network device
    fn get_proxy(&self) -> Option<IP4ConfigProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            IP4ConfigProxyBlocking::builder(conn)
                .path(self.path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [NetworkIpv4Config] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{NETWORK_MANAGER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<NetworkIpv4Config> = res.cast();
                device
            } else {
                let mut device = NetworkIpv4Config::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = NetworkIpv4Config::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    /// The gateway in use.
    #[func]
    pub fn get_gateway(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.gateway().unwrap_or_default().to_godot()
    }

    /// Array of IP address data objects. All addresses will include "address" (an IP address string), and "prefix" (a uint). Some addresses may include additional attributes.
    #[func]
    pub fn get_addresses(&self) -> Array<Dictionary> {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let mut value = array![];
        let data = proxy.address_data().unwrap_or_default();
        for entry in data {
            let mut dict = Dictionary::new();
            for (key, value) in entry.iter() {
                let Some(value) = value.as_godot_variant() else {
                    continue;
                };
                dict.set(key.to_godot(), value);
            }
            value.push(&dict);
        }

        value
    }

    /// Dispatches signals
    pub fn process(&mut self) {}
}

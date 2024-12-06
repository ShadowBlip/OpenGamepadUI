use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::udisks2::drive::DriveProxyBlocking;
use crate::get_dbus_system_blocking;

use super::UDISKS2_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct DriveDevice {
    base: Base<Resource>,
    conn: Option<zbus::blocking::Connection>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
}

#[godot_api]
impl DriveDevice {
    #[constant]
    const INTERFACE_TYPE_HDD: u16 = 0;
    #[constant]
    const INTERFACE_TYPE_NVME: u16 = 1;
    #[constant]
    const INTERFACE_TYPE_SD: u16 = 2;
    #[constant]
    const INTERFACE_TYPE_SSD: u16 = 3;
    #[constant]
    const INTERFACE_TYPE_USB: u16 = 4;
    #[constant]
    const INTERFACE_TYPE_UNKNOWN: u16 = 5;

    #[signal]
    fn updated();

    /// Create a new [DriveDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        log::debug!("DriveDevice created with path: {path}");

        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                dbus_path: path,
            }
        })
    }

    /// Return a proxy instance to the device
    fn get_proxy(&self) -> Option<DriveProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            let path: String = self.dbus_path.clone().into();
            DriveProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [DriveDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{UDISKS2_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<DriveDevice> = res.cast();
                device
            } else {
                let mut device = DriveDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = DriveDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Returns the drive devices interface type
    #[func]
    pub fn interface_type(&self) -> u16 {
        let Some(proxy) = self.get_proxy() else {
            return DriveDevice::INTERFACE_TYPE_UNKNOWN;
        };
        let Ok(connection) = proxy.connection_bus() else {
            return DriveDevice::INTERFACE_TYPE_UNKNOWN;
        };
        match connection.as_str() {
            "usb" => DriveDevice::INTERFACE_TYPE_USB,
            "sdio" => DriveDevice::INTERFACE_TYPE_SD,
            "" => {
                let Ok(sort_key) = proxy.sort_key() else {
                    return DriveDevice::INTERFACE_TYPE_UNKNOWN;
                };
                if sort_key.contains("hotplug") || sort_key.contains("removable") {
                    return DriveDevice::INTERFACE_TYPE_USB;
                } else if sort_key.contains("nvme") {
                    return DriveDevice::INTERFACE_TYPE_NVME;
                } else if sort_key.contains("sd_") {
                    let Ok(rotation_rate) = proxy.rotation_rate() else {
                        return DriveDevice::INTERFACE_TYPE_UNKNOWN;
                    };
                    if rotation_rate > 0 {
                        return DriveDevice::INTERFACE_TYPE_HDD;
                    }
                    return DriveDevice::INTERFACE_TYPE_SSD;
                }
                DriveDevice::INTERFACE_TYPE_UNKNOWN
            }
            _ => DriveDevice::INTERFACE_TYPE_UNKNOWN,
        }
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }
}

impl Drop for DriveDevice {
    fn drop(&mut self) {
        log::trace!("DriveDevice '{}' is being destroyed!", self.dbus_path);
    }
}

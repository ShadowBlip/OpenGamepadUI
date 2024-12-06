use godot::{classes::ResourceLoader, prelude::*};

use crate::{dbus::inputplumber::event_device::EventDeviceProxyBlocking, get_dbus_system_blocking};

use super::INPUT_PLUMBER_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct EventDevice {
    base: Base<Resource>,
    path: String,
    conn: Option<zbus::blocking::Connection>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    #[allow(dead_code)]
    #[var(get = get_name)]
    name: GString,
    #[allow(dead_code)]
    #[var(get = get_device_path)]
    device_path: GString,
    #[allow(dead_code)]
    #[var(get = get_phys_path)]
    phys_path: GString,
    #[allow(dead_code)]
    #[var(get = get_sysfs_path)]
    sysfs_path: GString,
    #[allow(dead_code)]
    #[var(get = get_unique_id)]
    unique_id: GString,
}

#[godot_api]
impl EventDevice {
    /// Create a new [EventDevice] with the given DBus path
    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                path: path.clone().into(),
                dbus_path: path,
                name: Default::default(),
                device_path: Default::default(),
                phys_path: Default::default(),
                sysfs_path: Default::default(),
                unique_id: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the composite device
    fn get_proxy(&self) -> Option<EventDeviceProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            EventDeviceProxyBlocking::builder(conn)
                .path(self.path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
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
                log::debug!("Resource already exists, loading that instead");
                let device: Gd<EventDevice> = res.cast();
                device
            } else {
                let mut device = EventDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = EventDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.clone().into()
    }

    /// Get the name of the [EventDevice]
    #[func]
    pub fn get_name(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return "".into();
        };
        proxy.name().unwrap_or_default().into()
    }

    #[func]
    pub fn get_device_path(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return "".into();
        };
        proxy.device_path().unwrap_or_default().into()
    }

    #[func]
    pub fn get_phys_path(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return "".into();
        };
        proxy.phys_path().unwrap_or_default().into()
    }

    #[func]
    pub fn get_sysfs_path(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return "".into();
        };
        proxy.sysfs_path().unwrap_or_default().into()
    }

    #[func]
    pub fn get_unique_id(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return "".into();
        };
        proxy.unique_id().unwrap_or_default().into()
    }
}

use godot::{classes::ResourceLoader, prelude::*};

use crate::{dbus::inputplumber::keyboard::KeyboardProxyBlocking, get_dbus_system_blocking};

use super::INPUT_PLUMBER_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct KeyboardDevice {
    base: Base<Resource>,
    path: String,
    conn: Option<zbus::blocking::Connection>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    #[allow(dead_code)]
    #[var(get = get_name)]
    name: GString,
}

#[godot_api]
impl KeyboardDevice {
    /// Create a new [KeyboardDevice] with the given DBus path
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
            }
        })
    }

    /// Return a proxy instance to the composite device
    fn get_proxy(&self) -> Option<KeyboardProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            KeyboardProxyBlocking::builder(conn)
                .path(self.path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [KeyboardDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{INPUT_PLUMBER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists, loading that instead");
                let device: Gd<KeyboardDevice> = res.cast();
                device
            } else {
                let mut device = KeyboardDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = KeyboardDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.clone().into()
    }

    /// Get the name of the [KeyboardDevice]
    #[func]
    pub fn get_name(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return "".into();
        };
        proxy.name().unwrap_or_default().into()
    }

    #[func]
    pub fn send_key(&self, key: GString, value: bool) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        let key_code: String = key.into();
        proxy.send_key(key_code.as_str(), value).ok();
    }
}

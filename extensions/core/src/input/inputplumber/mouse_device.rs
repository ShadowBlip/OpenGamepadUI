use godot::{classes::ResourceLoader, prelude::*};

use crate::{
    dbus::inputplumber::{mouse::MouseProxyBlocking, target::TargetProxyBlocking},
    get_dbus_system_blocking,
};

use super::INPUT_PLUMBER_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct MouseDevice {
    base: Base<Resource>,
    path: String,
    mouse_proxy: Option<MouseProxyBlocking<'static>>,
    target_proxy: Option<TargetProxyBlocking<'static>>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    #[allow(dead_code)]
    #[var(get = get_name)]
    name: GString,
    #[allow(dead_code)]
    #[var(get = get_type)]
    device_type: GString,
}

#[godot_api]
impl MouseDevice {
    /// Create a new [MouseDevice] with the given DBus path
    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Get a proxy instance to the composite device
            let mouse_proxy = if let Some(conn) = conn.as_ref() {
                MouseProxyBlocking::builder(conn)
                    .path(path.to_string())
                    .ok()
                    .and_then(|builder| builder.build().ok())
            } else {
                None
            };

            // Get a proxy instance to the composite device target interface
            let target_proxy = if let Some(conn) = conn.as_ref() {
                let path: String = path.clone().into();
                TargetProxyBlocking::builder(conn)
                    .path(path)
                    .ok()
                    .and_then(|builder| builder.build().ok())
            } else {
                None
            };

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                mouse_proxy,
                target_proxy,
                path: path.clone().into(),
                dbus_path: path,
                name: Default::default(),
                device_type: Default::default(),
            }
        })
    }

    /// Get or create a [MouseDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{INPUT_PLUMBER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists, loading that instead");
                let device: Gd<MouseDevice> = res.cast();
                device
            } else {
                let mut device = MouseDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = MouseDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.clone().into()
    }

    /// Get the name of the [MouseDevice]
    #[func]
    pub fn get_name(&self) -> GString {
        let Some(proxy) = self.mouse_proxy.as_ref() else {
            return "".into();
        };
        proxy.name().unwrap_or_default().into()
    }

    #[func]
    pub fn move_cursor(&self, x: i64, y: i64) {
        let Some(proxy) = self.mouse_proxy.as_ref() else {
            return;
        };
        proxy.move_cursor(x as i32, y as i32).ok();
    }

    /// Get the device_type of the [MouseDevice]
    #[func]
    pub fn get_type(&self) -> GString {
        let Some(proxy) = self.target_proxy.as_ref() else {
            return "".into();
        };
        proxy.device_type().unwrap_or_default().into()
    }
}

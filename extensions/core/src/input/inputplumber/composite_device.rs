use godot::prelude::*;

use godot::classes::{ProjectSettings, Resource, ResourceLoader};

use crate::dbus::inputplumber::composite_device::CompositeDeviceProxyBlocking;
use crate::dbus::DBusVariant;
use crate::get_dbus_system_blocking;

use super::dbus_device::DBusDevice;
use super::keyboard_device::KeyboardDevice;
use super::mouse_device::MouseDevice;
use super::INPUT_PLUMBER_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct CompositeDevice {
    base: Base<Resource>,

    conn: Option<zbus::blocking::Connection>,
    path: String,

    /// The DBus path of the [CompositeDevice]
    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    /// Name of the [CompositeDevice]
    #[allow(dead_code)]
    #[var(get = get_name)]
    name: GString,
    /// Name of the input profile that the [CompositeDevice] is using
    #[allow(dead_code)]
    #[var(get = get_profile_name)]
    profile_name: GString,
    /// Intercept mode of the [CompositeDevice]
    #[allow(dead_code)]
    #[var(get = get_intercept_mode, set = set_intercept_mode)]
    intercept_mode: i32,
    /// Capabilities from all source devices
    #[allow(dead_code)]
    #[var(get = get_capabilities)]
    capabilities: PackedStringArray,
    /// Capabilities from all target devices
    #[allow(dead_code)]
    #[var(get = get_target_capabilities)]
    target_capabilities: PackedStringArray,
    /// Target DBus devices associated with this composite device
    #[allow(dead_code)]
    #[var(get = get_dbus_devices)]
    dbus_devices: Array<Gd<DBusDevice>>,
    /// The source device paths of the composite device (e.g. /dev/input/event0)
    #[allow(dead_code)]
    #[var(get = get_source_device_paths)]
    source_device_paths: PackedStringArray,
}

#[godot_api]
impl CompositeDevice {
    /// Create a new [CompositeDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                conn,
                path: path.clone().into(), // Convert GString -> String.
                dbus_path: path,
                name: Default::default(),
                profile_name: Default::default(),
                intercept_mode: Default::default(),
                capabilities: Default::default(),
                target_capabilities: Default::default(),
                dbus_devices: Default::default(),
                source_device_paths: Default::default(),
                base,
            }
        })
    }

    /// Return a proxy instance to the composite device
    fn get_proxy(&self) -> Option<CompositeDeviceProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            CompositeDeviceProxyBlocking::builder(conn)
                .path(self.path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [CompositeDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{INPUT_PLUMBER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<CompositeDevice> = res.cast();
                device
            } else {
                let mut device = CompositeDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = CompositeDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Get the name of the [CompositeDevice]
    #[func]
    pub fn get_name(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return "".into();
        };
        proxy.name().ok().unwrap_or_default().into()
    }

    #[func]
    pub fn get_profile_name(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return "".into();
        };
        proxy.profile_name().ok().unwrap_or_default().into()
    }

    /// Get the intercept mode of the composite device
    #[func]
    pub fn get_intercept_mode(&self) -> i32 {
        let Some(proxy) = self.get_proxy() else {
            return -1;
        };
        proxy.intercept_mode().ok().unwrap_or_default() as i32
    }

    /// Set the intercept mode of the composite device
    #[func]
    pub fn set_intercept_mode(&self, mode: i32) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        let mode = mode as u32;
        proxy.set_intercept_mode(mode).ok();
    }

    /// Get capabilities from all source devices
    #[func]
    pub fn get_capabilities(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return PackedStringArray::new();
        };
        let caps: Vec<GString> = proxy
            .capabilities()
            .ok()
            .unwrap_or_default()
            .into_iter()
            .map(GString::from)
            .collect();
        PackedStringArray::from(caps.as_slice())
    }

    /// Get capabilities from all target devices
    #[func]
    pub fn get_target_capabilities(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return PackedStringArray::new();
        };
        let caps: Vec<GString> = proxy
            .target_capabilities()
            .ok()
            .unwrap_or_default()
            .into_iter()
            .map(GString::from)
            .collect();
        PackedStringArray::from(caps.as_slice())
    }

    #[func]
    pub fn get_dbus_devices(&self) -> Array<Gd<DBusDevice>> {
        let mut devices = array![];
        let paths = self.get_dbus_devices_paths();
        for path in paths.as_slice() {
            let dbus_path = String::from(path);
            let device = DBusDevice::new(dbus_path.as_str());
            devices.push(&device);
        }
        devices
    }

    #[func]
    pub fn get_dbus_devices_paths(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return PackedStringArray::new();
        };
        let values: Vec<GString> = proxy
            .dbus_devices()
            .ok()
            .unwrap_or_default()
            .into_iter()
            .map(GString::from)
            .collect();
        PackedStringArray::from(values.as_slice())
    }

    /// Get the source device paths of the composite device (e.g. /dev/input/event0)
    #[func]
    pub fn get_source_device_paths(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return PackedStringArray::new();
        };
        let values: Vec<GString> = proxy
            .source_device_paths()
            .ok()
            .unwrap_or_default()
            .into_iter()
            .map(GString::from)
            .collect();
        PackedStringArray::from(values.as_slice())
    }

    /// Get the target devices for the composite device
    #[func]
    pub fn get_target_devices(&self) -> Array<Variant> {
        let Some(proxy) = self.get_proxy() else {
            return array![];
        };
        let values = proxy.target_devices().ok().unwrap_or_default();
        let mut target_devices = array![];

        // Build the Godot object based on the path
        for path in values {
            if path.contains("gamepad") {
                // TODO
                continue;
            }
            if path.contains("keyboard") {
                let device = KeyboardDevice::new(path.as_str());
                target_devices.push(&device.to_variant());
                continue;
            }
            if path.contains("mouse") {
                let device = MouseDevice::new(path.as_str());
                target_devices.push(&device.to_variant());
                continue;
            }
            if path.contains("dbus") {
                let device = DBusDevice::new(path.as_str());
                target_devices.push(&device.to_variant());
                continue;
            }
        }

        target_devices
    }

    /// set the target device types for the composite device (e.g. "keyboard", "mouse", etc.)
    #[func]
    pub fn set_target_devices(&self, devices: PackedStringArray) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        let device_types: Vec<String> = devices.to_vec().into_iter().map(|v| v.into()).collect();
        let target_devices: Vec<&str> = device_types.iter().map(|v| v.as_str()).collect();
        proxy.set_target_devices(target_devices.as_slice()).ok();
    }

    /// Returns the DBus path to the [CompositeDevice]
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.clone().into()
    }

    /// Load the device profile from the given path
    #[func]
    pub fn load_profile_path(&self, path: GString) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        let path = String::from(path);
        let absolute_path = if path.starts_with("res://") || path.starts_with("user://") {
            let project_settings = ProjectSettings::singleton();
            project_settings.globalize_path(path.as_str()).into()
        } else {
            path
        };
        proxy.load_profile_path(absolute_path.as_str()).ok();
    }

    /// Write the given event to the appropriate target device, bypassing intercept
    /// logic.
    #[func]
    pub fn send_event(&self, action: GString, value: Variant) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        let Some(value) = value.as_zvariant() else {
            return;
        };
        let event = String::from(action);
        proxy.send_event(event.as_str(), &value).ok();
    }

    /// Write the given set of events as a button chord
    #[func]
    pub fn send_button_chord(&self, actions: PackedStringArray) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        let values: Vec<String> = actions.to_vec().into_iter().map(|v| v.into()).collect();
        let str_values: Vec<&str> = values.iter().map(|v| v.as_str()).collect();
        proxy.send_button_chord(str_values.as_slice()).ok();
    }

    /// Set the events to look for to activate input interception while in
    /// "PASS" mode.
    #[func]
    pub fn set_intercept_activation(&self, triggers: PackedStringArray, target_event: GString) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        let values: Vec<String> = triggers.to_vec().into_iter().map(|v| v.into()).collect();
        let str_values: Vec<&str> = values.iter().map(|v| v.as_str()).collect();
        let target_event: String = target_event.into();
        proxy
            .set_intercept_activation(str_values.as_slice(), target_event.as_str())
            .ok();
    }

    /// Dispatches signals
    pub fn process(&mut self) {}
}

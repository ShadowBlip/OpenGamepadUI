use std::collections::HashMap;

use godot::{classes::ResourceLoader, prelude::*};

use crate::{dbus::powerstation::fan::FanProxyBlocking, get_dbus_system_blocking};

use super::{fan_device::FanDevice, POWERSTATION_BUS};

/// A collection of fan devices exposed by PowerStation.
#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct Fan {
    base: Base<Resource>,
    path: String,
    proxy: Option<FanProxyBlocking<'static>>,
    devices: HashMap<String, Gd<FanDevice>>,
}

#[godot_api]
impl Fan {
    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            let conn = get_dbus_system_blocking().ok();
            let proxy = if let Some(conn) = conn.as_ref() {
                let path: String = path.clone().into();
                FanProxyBlocking::builder(conn)
                    .path(path)
                    .ok()
                    .and_then(|builder| builder.build().ok())
            } else {
                None
            };
            let mut instance = Self {
                base,
                proxy,
                path: path.clone().into(),
                devices: HashMap::new(),
            };
            instance.refresh_devices();
            instance
        })
    }

    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{POWERSTATION_BUS}{path}");
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                let mut fan: Gd<Fan> = res.cast();
                fan.bind_mut().refresh_devices();
                return fan;
            }
        }
        let mut device = Fan::from_path(path.into());
        device.take_over_path(res_path.as_str());
        device
    }

    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.as_str().into()
    }

    /// Refresh fan objects after service restart or hardware rediscovery.
    #[func]
    pub fn refresh(&mut self) {
        self.refresh_devices();
    }

    #[func]
    pub fn get_fans(&self) -> Array<Gd<FanDevice>> {
        let mut result = array![];
        let mut paths: Vec<_> = self.devices.keys().collect();
        paths.sort();
        for path in paths {
            if let Some(device) = self.devices.get(path) {
                result.push(device);
            }
        }
        result
    }

    pub fn process(&mut self) {
        for device in self.devices.values_mut() {
            device.bind_mut().process();
        }
    }

    fn refresh_devices(&mut self) {
        let paths = self
            .proxy
            .as_ref()
            .and_then(|proxy| proxy.enumerate_fans().ok())
            .unwrap_or_default();
        let mut devices = HashMap::new();
        for path in paths {
            let key = path.to_string();
            let device = self
                .devices
                .remove(&key)
                .unwrap_or_else(|| FanDevice::new(path.as_str()));
            devices.insert(key, device);
        }
        self.devices = devices;
    }
}

use std::fs::File;

use godot::{classes::ResourceLoader, global::Error, prelude::*};
use zbus::zvariant::Fd;

use crate::{
    dbus::powerstation::{fan::FanProxyBlocking, fan_device::FanDeviceProxyBlocking},
    get_dbus_system_blocking,
};

use super::POWERSTATION_BUS;

/// Fan control provided by PowerStation
#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct Fan {
    base: Base<Resource>,
    path: String,
    proxy: Option<FanProxyBlocking<'static>>,
}

#[godot_api]
impl Fan {
    /// Create a new [Fan] instance with the given DBus path
    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            let conn = get_dbus_system_blocking().ok();
            let proxy = conn.as_ref().and_then(|conn| {
                FanProxyBlocking::builder(conn)
                    .path(path.to_string())
                    .ok()
                    .and_then(|builder| builder.build().ok())
            });

            Self {
                base,
                path: path.to_string(),
                proxy,
            }
        })
    }

    /// Get or create a [Fan] with the given DBus path. If an instance already
    /// exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{POWERSTATION_BUS}{path}");

        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                return res.cast();
            }
        }
        let mut device = Fan::from_path(path.into());
        device.take_over_path(res_path.as_str());
        device
    }

    /// Return the DBus path to the fan instance
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.as_str().into()
    }

    /// Returns the IDs of all fans PowerStation can control
    #[func]
    pub fn get_fan_ids(&self) -> PackedStringArray {
        let mut ids = PackedStringArray::new();
        let Some(proxy) = self.proxy.as_ref() else {
            return ids;
        };
        let conn = proxy.inner().connection();
        for path in proxy.enumerate_fans().unwrap_or_default() {
            let Some(fan) = FanDeviceProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
            else {
                continue;
            };
            let Ok(id) = fan.id() else {
                continue;
            };
            ids.push(id.as_str());
        }
        ids
    }

    /// Returns the IDs of all temperature sensors
    #[func]
    pub fn get_sensors(&self) -> PackedStringArray {
        let Some(proxy) = self.proxy.as_ref() else {
            return PackedStringArray::new();
        };
        let sensors = proxy.sensors().unwrap_or_default();
        sensors.iter().map(|sensor| sensor.to_godot()).collect()
    }

    /// Returns the paths of the installed fan profiles for this device
    #[func]
    pub fn get_profiles(&self) -> PackedStringArray {
        let Some(proxy) = self.proxy.as_ref() else {
            return PackedStringArray::new();
        };
        let profiles = proxy.profiles().unwrap_or_default();
        profiles.iter().map(|profile| profile.to_godot()).collect()
    }

    /// Returns the name of the loaded fan profile
    #[func]
    pub fn get_profile_name(&self) -> GString {
        let Some(proxy) = self.proxy.as_ref() else {
            return GString::new();
        };
        proxy.profile_name().unwrap_or_default().as_str().into()
    }

    /// Returns the path of the loaded fan profile. Empty for profiles loaded
    /// from JSON.
    #[func]
    pub fn get_profile_path(&self) -> GString {
        let Some(proxy) = self.proxy.as_ref() else {
            return GString::new();
        };
        proxy.profile_path().unwrap_or_default().as_str().into()
    }

    /// Load the TOML fan profile at the given path
    #[func]
    pub fn load_profile(&self, path: GString) -> Error {
        let Some(proxy) = self.proxy.as_ref() else {
            return Error::ERR_UNAVAILABLE;
        };
        let file = match File::open(path.to_string()) {
            Ok(file) => file,
            Err(e) => {
                log::error!("Failed to open fan profile '{path}': {e}");
                return Error::ERR_FILE_CANT_OPEN;
            }
        };
        if let Err(e) = proxy.load_profile(Fd::from(&file)) {
            log::error!("Failed to load fan profile '{path}': {e}");
            return Error::FAILED;
        }
        Error::OK
    }

    /// Load a fan profile from a JSON string
    #[func]
    pub fn load_profile_json(&self, json: GString) -> Error {
        let Some(proxy) = self.proxy.as_ref() else {
            return Error::ERR_UNAVAILABLE;
        };
        if let Err(e) = proxy.load_profile_json(json.to_string().as_str()) {
            log::error!("Failed to load fan profile: {e}");
            return Error::FAILED;
        }
        Error::OK
    }
}

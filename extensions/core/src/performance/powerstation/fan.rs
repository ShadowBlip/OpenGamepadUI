use std::collections::HashMap;

use godot::{
    classes::{ProjectSettings, ResourceLoader},
    prelude::*,
};
use serde_json::{json, Value};

use crate::{dbus::powerstation::fan::FanProxyBlocking, get_dbus_system_blocking};

use super::{fan_client, fan_settings::FanSettings};
use super::{fan_device::FanDevice, POWERSTATION_BUS};
use crate::{get_dbus_system, RUNTIME};

/// A collection of fan devices exposed by PowerStation.
#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct Fan {
    base: Base<Resource>,
    path: String,
    proxy: Option<FanProxyBlocking<'static>>,
    devices: HashMap<String, Gd<FanDevice>>,
    last_error: String,
    restoration_attempted: bool,
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
                last_error: String::new(),
                restoration_attempted: false,
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

    #[func]
    pub fn get_last_error(&self) -> GString {
        self.last_error.as_str().into()
    }

    /// One owner-pinned snapshot, with no cached properties or raw hardware data.
    #[func]
    pub fn get_snapshot_json(&mut self) -> GString {
        match self.snapshot() {
            Ok(snapshot) => snapshot.to_string().as_str().into(),
            Err(error) => json!({"available": false, "fans": [], "sensors": [], "error": error})
                .to_string()
                .as_str()
                .into(),
        }
    }

    #[func]
    pub fn get_saved_selection_json(&mut self) -> GString {
        match Self::settings().load() {
            Ok(Some(value)) => value.to_string().as_str().into(),
            Ok(None) => "{}".into(),
            Err(error) => {
                self.last_error = error;
                "{}".into()
            }
        }
    }

    /// Apply an approved-directory YAML profile and save its reference on success.
    #[func]
    pub fn load_profile(&mut self, file: GString, owner: GString) -> bool {
        self.apply_selection(
            json!({"kind": "file", "file": file.to_string()}),
            &owner.to_string(),
            None,
        )
    }

    /// Apply a complete profile, then save only a confirmed selection.
    #[func]
    pub fn load_profile_json(&mut self, raw: GString, owner: GString) -> bool {
        let raw = raw.to_string();
        if raw.len() > fan_client::MAX_PROFILE_BYTES {
            self.last_error = "Fan profile exceeds 64 KiB".into();
            return false;
        }
        match serde_json::from_str::<Value>(&raw) {
            Ok(profile) => self.apply_selection(
                json!({"kind": "json", "profile": profile}),
                &owner.to_string(),
                None,
            ),
            Err(error) => {
                self.last_error = format!("Invalid fan profile JSON: {error}");
                false
            }
        }
    }

    /// Called once by the application, never by a remounted menu or recovery loop.
    #[func]
    pub fn restore_saved(&mut self) -> bool {
        if self.restoration_attempted {
            return false;
        }
        self.restoration_attempted = true;
        let settings = Self::settings();
        let result = RUNTIME.block_on(async {
            tokio::time::timeout(fan_client::TIMEOUT, async {
                let connection = get_dbus_system().await.map_err(|e| e.to_string())?;
                fan_client::restore(&connection, &settings).await
            })
            .await
            .map_err(|_| {
                "Fan restoration timed out; it will not be retried automatically".to_string()
            })?
        });
        match result {
            Ok(()) => {
                self.last_error.clear();
                true
            }
            Err(error) => {
                self.last_error = error;
                false
            }
        }
    }

    fn snapshot(&self) -> Result<Value, String> {
        RUNTIME.block_on(async {
            tokio::time::timeout(fan_client::TIMEOUT, async {
                let connection = get_dbus_system().await.map_err(|e| e.to_string())?;
                fan_client::snapshot(&connection).await
            })
            .await
            .map_err(|_| "PowerStation fan snapshot timed out".to_string())?
        })
    }

    fn settings() -> FanSettings {
        let path = ProjectSettings::singleton().globalize_path("user://data/fans");
        FanSettings::new(path.to_string().into())
    }

    fn apply_selection(
        &mut self,
        selection: Value,
        owner: &str,
        startup: Option<(&str, &str)>,
    ) -> bool {
        let result = RUNTIME.block_on(async {
            tokio::time::timeout(fan_client::TIMEOUT, async {
                let connection = get_dbus_system().await.map_err(|e| e.to_string())?;
                fan_client::apply(&connection, owner, &selection, startup).await
            })
            .await
            .map_err(|_| {
                "Fan profile request timed out; it will not be retried automatically".to_string()
            })?
        });
        if let Err(error) = result {
            self.last_error = error;
            return false;
        }
        match Self::settings().save(&selection) {
            Ok(()) => {
                self.last_error.clear();
                true
            }
            Err(error) => {
                self.last_error =
                    format!("Profile applied, but preferences could not be saved: {error}");
                false
            }
        }
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

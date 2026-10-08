use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use futures_util::StreamExt;
use godot::{classes::ResourceLoader, prelude::*};

use crate::{
    dbus::{
        powerstation::fan_device::{FanDeviceProxy, FanDeviceProxyBlocking},
        RunError,
    },
    get_dbus_system, get_dbus_system_blocking, RUNTIME,
};

use super::POWERSTATION_BUS;

#[derive(Debug)]
enum Signal {
    Updated,
}

/// A single PowerStation fan and its atomic control operations.
#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct FanDevice {
    base: Base<Resource>,
    dbus_path: String,
    proxy: Option<FanDeviceProxyBlocking<'static>>,
    rx: Receiver<Signal>,
    last_error: String,
}

#[godot_api]
impl FanDevice {
    #[signal]
    fn updated();

    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            let conn = get_dbus_system_blocking().ok();
            let (tx, rx) = channel();
            let dbus_path: String = path.clone().into();
            RUNTIME.spawn(async move {
                if let Err(error) = run(tx, dbus_path).await {
                    log::error!("Failed to run fan device task: {error:?}");
                }
            });
            let proxy = if let Some(conn) = conn.as_ref() {
                let dbus_path: String = path.clone().into();
                FanDeviceProxyBlocking::builder(conn)
                    .path(dbus_path)
                    .ok()
                    .and_then(|builder| builder.build().ok())
            } else {
                None
            };
            Self {
                base,
                proxy,
                dbus_path: path.into(),
                rx,
                last_error: String::new(),
            }
        })
    }

    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{POWERSTATION_BUS}{path}");
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                return res.cast();
            }
        }
        let mut device = FanDevice::from_path(path.into());
        device.take_over_path(res_path.as_str());
        device
    }

    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.as_str().into()
    }

    #[func]
    pub fn get_last_error(&self) -> GString {
        self.last_error.as_str().into()
    }

    #[func]
    pub fn get_api_version(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.api_version().ok())
            .unwrap_or(0) as i64
    }

    #[func]
    pub fn get_id(&self) -> GString {
        self.string_property(|p| p.id())
    }

    #[func]
    pub fn get_name(&self) -> GString {
        self.string_property(|p| p.name())
    }

    #[func]
    pub fn get_mode(&self) -> GString {
        self.string_property(|p| p.mode())
    }

    #[func]
    pub fn get_backend(&self) -> GString {
        self.string_property(|p| p.backend())
    }

    #[func]
    pub fn get_temperature_c(&self) -> f64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.temperature_c().ok())
            .unwrap_or_default()
    }

    #[func]
    pub fn get_telemetry_valid(&self) -> bool {
        self.proxy
            .as_ref()
            .and_then(|p| p.telemetry_valid().ok())
            .unwrap_or(false)
    }

    #[func]
    pub fn get_rpm(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.rpm().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_effective_percent(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.effective_percent().ok())
            .unwrap_or(-1) as i64
    }

    #[func]
    pub fn get_manual_percent(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.manual_percent().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_presets(&self) -> PackedStringArray {
        self.string_array_property(|p| p.presets())
    }

    #[func]
    pub fn get_active_preset(&self) -> GString {
        self.string_property(|p| p.active_preset())
    }

    #[func]
    pub fn get_fault(&self) -> GString {
        self.string_property(|p| p.fault())
    }

    #[func]
    pub fn get_automatic_verified(&self) -> bool {
        self.proxy
            .as_ref()
            .and_then(|p| p.automatic_verified().ok())
            .unwrap_or(false)
    }

    #[func]
    pub fn get_controlling(&self) -> bool {
        self.proxy
            .as_ref()
            .and_then(|p| p.controlling().ok())
            .unwrap_or(false)
    }

    #[func]
    pub fn get_suspended(&self) -> bool {
        self.proxy
            .as_ref()
            .and_then(|p| p.suspended().ok())
            .unwrap_or(false)
    }

    #[func]
    pub fn get_curve_temperatures(&self) -> PackedFloat64Array {
        let values: Vec<f64> = self.curve().into_iter().map(|point| point.0).collect();
        PackedFloat64Array::from(values.as_slice())
    }

    #[func]
    pub fn get_curve_percents(&self) -> PackedInt32Array {
        let values: Vec<i32> = self
            .curve()
            .into_iter()
            .map(|point| i32::from(point.1))
            .collect();
        PackedInt32Array::from(values.as_slice())
    }

    #[func]
    pub fn get_curve_point_count(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.curve_point_count().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_minimum_percent(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.minimum_percent().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_minimum_running_percent(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.minimum_running_percent().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_pwm_min(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.pwm_min().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_pwm_max(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.pwm_max().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_pwm_readback_tolerance(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.pwm_readback_tolerance().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_stop_temperature_c(&self) -> f64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.stop_temperature_c().ok())
            .unwrap_or_default()
    }

    #[func]
    pub fn get_restart_temperature_c(&self) -> f64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.restart_temperature_c().ok())
            .unwrap_or_default()
    }

    #[func]
    pub fn get_stall_rpm(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.stall_rpm().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_stall_grace_seconds(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.stall_grace_seconds().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn get_full_speed_temperature_c(&self) -> f64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.full_speed_temperature_c().ok())
            .unwrap_or_default()
    }

    #[func]
    pub fn get_emergency_handoff_temperature_c(&self) -> f64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.emergency_handoff_temperature_c().ok())
            .unwrap_or_default()
    }

    #[func]
    pub fn get_minimum_valid_temperature_c(&self) -> f64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.minimum_valid_temperature_c().ok())
            .unwrap_or_default()
    }

    #[func]
    pub fn get_maximum_valid_temperature_c(&self) -> f64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.maximum_valid_temperature_c().ok())
            .unwrap_or_default()
    }

    #[func]
    pub fn get_maximum_valid_rpm(&self) -> i64 {
        self.proxy
            .as_ref()
            .and_then(|p| p.maximum_valid_rpm().ok())
            .unwrap_or_default() as i64
    }

    #[func]
    pub fn set_automatic(&mut self) -> bool {
        self.perform(|proxy| proxy.set_automatic())
    }

    #[func]
    pub fn set_manual(&mut self, percent: i64) -> bool {
        if !(0..=100).contains(&percent) {
            self.last_error = "Fan duty must be between 0 and 100 percent".into();
            return false;
        }
        self.perform(|proxy| proxy.set_manual(percent as u8))
    }

    /// Apply a complete curve in one D-Bus operation.
    #[func]
    pub fn set_curve(
        &mut self,
        temperatures: PackedFloat64Array,
        percents: PackedInt32Array,
    ) -> bool {
        if temperatures.len() != percents.len() || temperatures.len() < 2 {
            self.last_error = "A fan curve needs matching temperature and duty arrays".into();
            return false;
        }
        let mut points = Vec::with_capacity(temperatures.len());
        for index in 0..temperatures.len() {
            let percent = percents[index];
            if !(0..=100).contains(&percent) {
                self.last_error = "Fan curve duty must be between 0 and 100 percent".into();
                return false;
            }
            points.push((temperatures[index], percent as u8));
        }
        self.perform(|proxy| proxy.set_curve(points))
    }

    #[func]
    pub fn apply_preset(&mut self, name: GString) -> bool {
        let name = name.to_string();
        self.perform(|proxy| proxy.apply_preset(name.as_str()))
    }

    pub fn process(&mut self) {
        loop {
            match self.rx.try_recv() {
                Ok(Signal::Updated) => {
                    self.base_mut().emit_signal("updated", &[]);
                }
                Err(TryRecvError::Empty) => break,
                Err(TryRecvError::Disconnected) => return,
            }
        }
    }

    fn curve(&self) -> Vec<(f64, u8)> {
        self.proxy
            .as_ref()
            .and_then(|p| p.curve().ok())
            .unwrap_or_default()
    }

    fn string_property<F>(&self, getter: F) -> GString
    where
        F: FnOnce(&FanDeviceProxyBlocking<'static>) -> zbus::Result<String>,
    {
        let value = self
            .proxy
            .as_ref()
            .and_then(|p| getter(p).ok())
            .unwrap_or_default();
        value.as_str().into()
    }

    fn string_array_property<F>(&self, getter: F) -> PackedStringArray
    where
        F: FnOnce(&FanDeviceProxyBlocking<'static>) -> zbus::Result<Vec<String>>,
    {
        let values: Vec<GString> = self
            .proxy
            .as_ref()
            .and_then(|p| getter(p).ok())
            .unwrap_or_default()
            .into_iter()
            .map(|value| value.as_str().into())
            .collect();
        PackedStringArray::from(values.as_slice())
    }

    fn perform<F>(&mut self, operation: F) -> bool
    where
        F: FnOnce(&FanDeviceProxyBlocking<'static>) -> zbus::Result<()>,
    {
        let Some(proxy) = self.proxy.as_ref() else {
            self.last_error = "PowerStation fan service is unavailable".into();
            return false;
        };
        match proxy.api_version() {
            Ok(1) => {}
            Ok(version) => {
                self.last_error = format!(
                    "Incompatible PowerStation fan API version {version}; version 1 is required"
                );
                return false;
            }
            Err(error) => {
                self.last_error = format!("Unable to verify the PowerStation fan API: {error}");
                return false;
            }
        }
        match operation(proxy) {
            Ok(()) => {
                self.last_error.clear();
                true
            }
            Err(error) => {
                self.last_error = error.to_string();
                false
            }
        }
    }
}

async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    let conn = get_dbus_system().await?;
    let proxy = FanDeviceProxy::builder(&conn).path(path)?.build().await?;
    // PowerStation emits Mode with every telemetry/configuration snapshot, so a
    // single stream keeps Godot updates coalesced to one event per controller tick.
    let mut changed = proxy.receive_mode_changed().await;
    while changed.next().await.is_some() {
        if tx.send(Signal::Updated).is_err() {
            break;
        }
    }
    Ok(())
}

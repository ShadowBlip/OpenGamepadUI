//! D-Bus proxy for a PowerStation fan device.

use zbus::proxy;

#[proxy(
    interface = "org.shadowblip.Fan.Device",
    default_service = "org.shadowblip.PowerStation"
)]
pub trait FanDevice {
    fn set_automatic(&self) -> zbus::Result<()>;
    fn set_manual(&self, percent: u8) -> zbus::Result<()>;
    fn set_curve(&self, points: Vec<(f64, u8)>) -> zbus::Result<()>;
    fn apply_preset(&self, name: &str) -> zbus::Result<()>;

    #[zbus(property)]
    fn api_version(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn id(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn name(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn mode(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn backend(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn available_modes(&self) -> zbus::Result<Vec<String>>;
    #[zbus(property)]
    fn temperature_c(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn telemetry_valid(&self) -> zbus::Result<bool>;
    #[zbus(property)]
    fn rpm(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn effective_percent(&self) -> zbus::Result<i16>;
    #[zbus(property)]
    fn manual_percent(&self) -> zbus::Result<u8>;
    #[zbus(property)]
    fn curve(&self) -> zbus::Result<Vec<(f64, u8)>>;
    #[zbus(property)]
    fn presets(&self) -> zbus::Result<Vec<String>>;
    #[zbus(property)]
    fn active_preset(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn fault(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn automatic_verified(&self) -> zbus::Result<bool>;
    #[zbus(property)]
    fn controlling(&self) -> zbus::Result<bool>;
    #[zbus(property)]
    fn suspended(&self) -> zbus::Result<bool>;
    #[zbus(property)]
    fn curve_point_count(&self) -> zbus::Result<u16>;
    #[zbus(property)]
    fn minimum_percent(&self) -> zbus::Result<u8>;
    #[zbus(property)]
    fn minimum_running_percent(&self) -> zbus::Result<u8>;
    #[zbus(property)]
    fn pwm_min(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn pwm_max(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn pwm_readback_tolerance(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn stop_temperature_c(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn restart_temperature_c(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn stall_rpm(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn stall_grace_seconds(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn full_speed_temperature_c(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn emergency_handoff_temperature_c(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn minimum_valid_temperature_c(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn maximum_valid_temperature_c(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn maximum_valid_rpm(&self) -> zbus::Result<u32>;
}

//! InputPlumber's versioned, whole-configuration LED interface.
use zbus::proxy;

pub const LED_INTERFACE: &str = "org.shadowblip.Input.Source.LEDDevice";
pub type LedConfiguration = (String, Vec<u8>, u32, u32);
pub type LedCapabilities = (u32, String, Vec<String>, u32, u32);
pub type LedState = (u64, LedConfiguration, String, String);

#[proxy(
    interface = "org.shadowblip.Input.Source.LEDDevice",
    default_service = "org.shadowblip.InputPlumber"
)]
pub trait LedDevice {
    #[zbus(property)]
    fn id(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn capabilities(&self) -> zbus::Result<LedCapabilities>;
    #[zbus(property)]
    fn state(&self) -> zbus::Result<LedState>;
    fn set_config(&self, config: LedConfiguration) -> zbus::Result<u64>;
}

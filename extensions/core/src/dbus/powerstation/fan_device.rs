//! Percentage-only API v2 fan state. Profile writes belong to the collection.
use zbus::proxy;

#[proxy(
    interface = "org.shadowblip.Fan.Device",
    default_service = "org.shadowblip.PowerStation"
)]
pub trait FanDevice {
    #[zbus(property)]
    fn id(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn name(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn mode(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn available_modes(&self) -> zbus::Result<Vec<String>>;
    #[zbus(property)]
    fn percent(&self) -> zbus::Result<u8>;
    #[zbus(property)]
    fn percent_valid(&self) -> zbus::Result<bool>;
    #[zbus(property)]
    fn fault(&self) -> zbus::Result<String>;
}

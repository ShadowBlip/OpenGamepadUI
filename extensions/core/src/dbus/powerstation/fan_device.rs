use zbus::proxy;
#[proxy(
    interface = "org.shadowblip.Fan.Device",
    default_service = "org.shadowblip.PowerStation",
    default_path = "/org/shadowblip/Performance/Fan/Fan0"
)]
pub trait FanDevice {
    /// AvailableModes property
    #[zbus(property)]
    fn available_modes(&self) -> zbus::Result<Vec<String>>;

    /// Id property
    #[zbus(property)]
    fn id(&self) -> zbus::Result<String>;

    /// Mode property
    #[zbus(property)]
    fn mode(&self) -> zbus::Result<String>;

    /// Percent property
    #[zbus(property)]
    fn percent(&self) -> zbus::Result<u8>;
}

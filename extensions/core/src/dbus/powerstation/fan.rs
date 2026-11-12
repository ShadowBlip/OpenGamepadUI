use zbus::proxy;
#[proxy(
    interface = "org.shadowblip.Fan",
    default_service = "org.shadowblip.PowerStation",
    default_path = "/org/shadowblip/Performance/Fan"
)]
pub trait Fan {
    /// EnumerateFans method
    fn enumerate_fans(&self) -> zbus::Result<Vec<zbus::zvariant::OwnedObjectPath>>;

    /// LoadProfile method
    fn load_profile(&self, file: zbus::zvariant::Fd<'_>) -> zbus::Result<()>;

    /// LoadProfileJson method
    fn load_profile_json(&self, json: &str) -> zbus::Result<()>;

    /// ProfileName property
    #[zbus(property)]
    fn profile_name(&self) -> zbus::Result<String>;

    /// ProfilePath property
    #[zbus(property)]
    fn profile_path(&self) -> zbus::Result<String>;

    /// Profiles property
    #[zbus(property)]
    fn profiles(&self) -> zbus::Result<Vec<String>>;

    /// Sensors property
    #[zbus(property)]
    fn sensors(&self) -> zbus::Result<Vec<String>>;
}

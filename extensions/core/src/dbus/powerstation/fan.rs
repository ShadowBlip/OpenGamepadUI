//! D-Bus proxy for the PowerStation fan collection.

use zbus::proxy;

#[proxy(
    interface = "org.shadowblip.Fan",
    default_service = "org.shadowblip.PowerStation",
    default_path = "/org/shadowblip/Performance/Fan"
)]
pub trait Fan {
    fn load_profile(&self, file: &str) -> zbus::Result<()>;
    fn load_profile_json(&self, json: &str) -> zbus::Result<()>;
    fn get_startup_status(&self) -> zbus::Result<(String, String, bool)>;
    fn load_startup_profile_json(
        &self,
        boot_id: &str,
        invocation_id: &str,
        json: &str,
    ) -> zbus::Result<()>;
    fn load_startup_profile(
        &self,
        boot_id: &str,
        invocation_id: &str,
        file: &str,
    ) -> zbus::Result<()>;
    /// Return every fan exposed by PowerStation.
    fn enumerate_fans(&self) -> zbus::Result<Vec<zbus::zvariant::OwnedObjectPath>>;
    fn enumerate_sensors(&self) -> zbus::Result<Vec<zbus::zvariant::OwnedObjectPath>>;
    #[zbus(property)]
    fn api_version(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn current_profile_name(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn current_profile_path(&self) -> zbus::Result<String>;
}

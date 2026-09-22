//! D-Bus proxy for the PowerStation fan collection.

use zbus::proxy;

#[proxy(
    interface = "org.shadowblip.Fan",
    default_service = "org.shadowblip.PowerStation",
    default_path = "/org/shadowblip/Performance/Fan"
)]
pub trait Fan {
    /// Return every fan exposed by PowerStation.
    fn enumerate_fans(&self) -> zbus::Result<Vec<zbus::zvariant::OwnedObjectPath>>;
}

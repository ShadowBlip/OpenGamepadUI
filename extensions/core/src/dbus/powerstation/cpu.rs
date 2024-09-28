//! # D-Bus interface proxy for: `org.shadowblip.CPU`
//!
//! This code was generated by `zbus-xmlgen` `4.1.0` from D-Bus introspection data.
//! Source: `Interface '/org/shadowblip/Performance/CPU' from service 'org.shadowblip.PowerStation' on system bus`.
//!
//! You may prefer to adapt it, instead of using it verbatim.
//!
//! More information can be found in the [Writing a client proxy] section of the zbus
//! documentation.
//!
//! This type implements the [D-Bus standard interfaces], (`org.freedesktop.DBus.*`) for which the
//! following zbus API can be used:
//!
//! * [`zbus::fdo::PeerProxy`]
//! * [`zbus::fdo::IntrospectableProxy`]
//! * [`zbus::fdo::PropertiesProxy`]
//!
//! Consequently `zbus-xmlgen` did not generate code for the above interfaces.
//!
//! [Writing a client proxy]: https://dbus2.github.io/zbus/client.html
//! [D-Bus standard interfaces]: https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces,
use zbus::proxy;
#[proxy(
    interface = "org.shadowblip.CPU",
    default_service = "org.shadowblip.PowerStation",
    default_path = "/org/shadowblip/Performance/CPU"
)]
trait CPU {
    /// EnumerateCores method
    fn enumerate_cores(&self) -> zbus::Result<Vec<zbus::zvariant::OwnedObjectPath>>;

    /// HasFeature method
    fn has_feature(&self, flag: &str) -> zbus::Result<bool>;

    /// BoostEnabled property
    #[zbus(property)]
    fn boost_enabled(&self) -> zbus::Result<bool>;
    #[zbus(property)]
    fn set_boost_enabled(&self, value: bool) -> zbus::Result<()>;

    /// CoresCount property
    #[zbus(property)]
    fn cores_count(&self) -> zbus::Result<u32>;

    /// CoresEnabled property
    #[zbus(property)]
    fn cores_enabled(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn set_cores_enabled(&self, value: u32) -> zbus::Result<()>;

    /// Features property
    #[zbus(property)]
    fn features(&self) -> zbus::Result<Vec<String>>;

    /// SmtEnabled property
    #[zbus(property)]
    fn smt_enabled(&self) -> zbus::Result<bool>;
    #[zbus(property)]
    fn set_smt_enabled(&self, value: bool) -> zbus::Result<()>;
}
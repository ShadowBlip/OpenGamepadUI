//! # D-Bus interface proxy for: `org.shadowblip.GPU.Card.TDP`
//!
//! This code was generated by `zbus-xmlgen` `4.1.0` from D-Bus introspection data.
//! Source: `Interface '/org/shadowblip/Performance/GPU/card0' from service 'org.shadowblip.PowerStation' on system bus`.
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
//! * [`zbus::fdo::PropertiesProxy`]
//! * [`zbus::fdo::IntrospectableProxy`]
//!
//! Consequently `zbus-xmlgen` did not generate code for the above interfaces.
//!
//! [Writing a client proxy]: https://dbus2.github.io/zbus/client.html
//! [D-Bus standard interfaces]: https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces,
use zbus::proxy;
#[proxy(
    interface = "org.shadowblip.GPU.Card.TDP",
    default_service = "org.shadowblip.PowerStation",
    default_path = "/org/shadowblip/Performance/GPU/card0"
)]
trait TDP {
    /// Boost property
    #[zbus(property)]
    fn boost(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn set_boost(&self, value: f64) -> zbus::Result<()>;

    /// PowerProfile property
    #[zbus(property)]
    fn power_profile(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn set_power_profile(&self, value: &str) -> zbus::Result<()>;

    /// TDP property
    #[zbus(property, name = "TDP")]
    fn tdp(&self) -> zbus::Result<f64>;
    #[zbus(property, name = "TDP")]
    fn set_tdp(&self, value: f64) -> zbus::Result<()>;

    /// ThermalThrottleLimitC property
    #[zbus(property)]
    fn thermal_throttle_limit_c(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn set_thermal_throttle_limit_c(&self, value: f64) -> zbus::Result<()>;
}
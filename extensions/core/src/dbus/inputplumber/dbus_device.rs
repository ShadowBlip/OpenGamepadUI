//! # D-Bus interface proxy for: `org.shadowblip.Input.DBusDevice`
//!
//! This code was generated by `zbus-xmlgen` `4.1.0` from D-Bus introspection data.
//! Source: `Interface '/org/shadowblip/InputPlumber/devices/target/dbus0' from service 'org.shadowblip.InputPlumber' on system bus`.
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
    interface = "org.shadowblip.Input.DBusDevice",
    default_service = "org.shadowblip.InputPlumber",
    default_path = "/org/shadowblip/InputPlumber/devices/target/dbus0"
)]
trait DBusDevice {
    /// InputEvent signal
    #[zbus(signal)]
    fn input_event(&self, event: &str, value: f64) -> zbus::Result<()>;

    /// TouchEvent signal
    #[zbus(signal)]
    fn touch_event(
        &self,
        event: &str,
        index: u32,
        is_touching: bool,
        pressure: f64,
        x: f64,
        y: f64,
    ) -> zbus::Result<()>;

    /// Name property
    #[zbus(property)]
    fn name(&self) -> zbus::Result<String>;
}
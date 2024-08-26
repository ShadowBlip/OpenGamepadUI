//! # D-Bus interface proxy for: `org.shadowblip.Input.CompositeDevice`
//!
//! This code was generated by `zbus-xmlgen` `4.1.0` from D-Bus introspection data.
//! Source: `Interface '/org/shadowblip/InputPlumber/CompositeDevice0' from service 'org.shadowblip.InputPlumber' on system bus`.
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
    interface = "org.shadowblip.Input.CompositeDevice",
    default_service = "org.shadowblip.InputPlumber",
    default_path = "/org/shadowblip/InputPlumber/CompositeDevice0"
)]
trait CompositeDevice {
    /// LoadProfileFromYaml method
    fn load_profile_from_yaml(&self, profile: &str) -> zbus::Result<()>;

    /// LoadProfilePath method
    fn load_profile_path(&self, path: &str) -> zbus::Result<()>;

    /// SendButtonChord method
    fn send_button_chord(&self, events: &[&str]) -> zbus::Result<()>;

    /// SendEvent method
    fn send_event(&self, event: &str, value: &zbus::zvariant::Value<'_>) -> zbus::Result<()>;

    /// SetInterceptActivation method
    fn set_intercept_activation(
        &self,
        activation_events: &[&str],
        target_event: &str,
    ) -> zbus::Result<()>;

    /// SetTargetDevices method
    fn set_target_devices(&self, target_device_types: &[&str]) -> zbus::Result<()>;

    /// Stop method
    fn stop(&self) -> zbus::Result<()>;

    /// Capabilities property
    #[zbus(property)]
    fn capabilities(&self) -> zbus::Result<Vec<String>>;

    /// DbusDevices property
    #[zbus(property)]
    fn dbus_devices(&self) -> zbus::Result<Vec<String>>;

    /// InterceptMode property
    #[zbus(property)]
    fn intercept_mode(&self) -> zbus::Result<u32>;
    #[zbus(property)]
    fn set_intercept_mode(&self, value: u32) -> zbus::Result<()>;

    /// Name property
    #[zbus(property)]
    fn name(&self) -> zbus::Result<String>;

    /// ProfileName property
    #[zbus(property)]
    fn profile_name(&self) -> zbus::Result<String>;

    /// SourceDevicePaths property
    #[zbus(property)]
    fn source_device_paths(&self) -> zbus::Result<Vec<String>>;

    /// TargetCapabilities property
    #[zbus(property)]
    fn target_capabilities(&self) -> zbus::Result<Vec<String>>;

    /// TargetDevices property
    #[zbus(property)]
    fn target_devices(&self) -> zbus::Result<Vec<String>>;
}

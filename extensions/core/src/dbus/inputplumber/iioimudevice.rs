//! # D-Bus interface proxy for: `org.shadowblip.Input.Source.IIOIMUDevice`
//!
//! This code was generated by `zbus-xmlgen` `4.1.0` from D-Bus introspection data.
//! Source: `Interface '/org/shadowblip/InputPlumber/devices/source/iio_device0' from service 'org.shadowblip.InputPlumber' on system bus`.
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
    interface = "org.shadowblip.Input.Source.IIOIMUDevice",
    default_service = "org.shadowblip.InputPlumber",
    default_path = "/org/shadowblip/InputPlumber/devices/source/iio_device0"
)]
trait IIOIMUDevice {
    /// AccelSampleRate property
    #[zbus(property)]
    fn accel_sample_rate(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn set_accel_sample_rate(&self, value: f64) -> zbus::Result<()>;

    /// AccelSampleRatesAvail property
    #[zbus(property)]
    fn accel_sample_rates_avail(&self) -> zbus::Result<Vec<f64>>;

    /// AccelScale property
    #[zbus(property)]
    fn accel_scale(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn set_accel_scale(&self, value: f64) -> zbus::Result<()>;

    /// AccelScalesAvail property
    #[zbus(property)]
    fn accel_scales_avail(&self) -> zbus::Result<Vec<f64>>;

    /// AngvelSampleRate property
    #[zbus(property)]
    fn angvel_sample_rate(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn set_angvel_sample_rate(&self, value: f64) -> zbus::Result<()>;

    /// AngvelSampleRatesAvail property
    #[zbus(property)]
    fn angvel_sample_rates_avail(&self) -> zbus::Result<Vec<f64>>;

    /// AngvelScale property
    #[zbus(property)]
    fn angvel_scale(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn set_angvel_scale(&self, value: f64) -> zbus::Result<()>;

    /// AngvelScalesAvail property
    #[zbus(property)]
    fn angvel_scales_avail(&self) -> zbus::Result<Vec<f64>>;

    /// Id property
    #[zbus(property)]
    fn id(&self) -> zbus::Result<String>;

    /// Name property
    #[zbus(property)]
    fn name(&self) -> zbus::Result<String>;
}

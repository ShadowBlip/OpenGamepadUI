//! # D-Bus interface proxy for: `org.freedesktop.UDisks2.Drive`
//!
//! This code was generated by `zbus-xmlgen` `4.1.0` from D-Bus introspection data.
//! Source: `Interface '/org/freedesktop/UDisks2/drives/xxxx' from service 'org.freedesktop.UDisks2' on system bus`.
//!
//! You may prefer to adapt it, instead of using it verbatim.
//!
//! More information can be found in the [Writing a client proxy] section of the zbus
//! documentation.
//!
//! This type implements the [D-Bus standard interfaces], (`org.freedesktop.DBus.*`) for which the
//! following zbus API can be used:
//!
//! * [`zbus::fdo::PropertiesProxy`]
//! * [`zbus::fdo::IntrospectableProxy`]
//! * [`zbus::fdo::PeerProxy`]
//!
//! Consequently `zbus-xmlgen` did not generate code for the above interfaces.
//!
//! [Writing a client proxy]: https://dbus2.github.io/zbus/client.html
//! [D-Bus standard interfaces]: https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces,
use zbus::proxy;
#[proxy(
    interface = "org.freedesktop.UDisks2.Drive",
    default_service = "org.freedesktop.UDisks2"
)]
trait Drive {
    /// Eject method
    fn eject(
        &self,
        options: std::collections::HashMap<&str, &zbus::zvariant::Value<'_>>,
    ) -> zbus::Result<()>;

    /// PowerOff method
    fn power_off(
        &self,
        options: std::collections::HashMap<&str, &zbus::zvariant::Value<'_>>,
    ) -> zbus::Result<()>;

    /// SetConfiguration method
    fn set_configuration(
        &self,
        value: std::collections::HashMap<&str, &zbus::zvariant::Value<'_>>,
        options: std::collections::HashMap<&str, &zbus::zvariant::Value<'_>>,
    ) -> zbus::Result<()>;

    /// CanPowerOff property
    #[zbus(property)]
    fn can_power_off(&self) -> zbus::Result<bool>;

    /// Configuration property
    #[zbus(property)]
    fn configuration(
        &self,
    ) -> zbus::Result<std::collections::HashMap<String, zbus::zvariant::OwnedValue>>;

    /// ConnectionBus property
    #[zbus(property)]
    fn connection_bus(&self) -> zbus::Result<String>;

    /// Ejectable property
    #[zbus(property)]
    fn ejectable(&self) -> zbus::Result<bool>;

    /// Id property
    #[zbus(property)]
    fn id(&self) -> zbus::Result<String>;

    /// Media property
    #[zbus(property)]
    fn media(&self) -> zbus::Result<String>;

    /// MediaAvailable property
    #[zbus(property)]
    fn media_available(&self) -> zbus::Result<bool>;

    /// MediaChangeDetected property
    #[zbus(property)]
    fn media_change_detected(&self) -> zbus::Result<bool>;

    /// MediaCompatibility property
    #[zbus(property)]
    fn media_compatibility(&self) -> zbus::Result<Vec<String>>;

    /// MediaRemovable property
    #[zbus(property)]
    fn media_removable(&self) -> zbus::Result<bool>;

    /// Model property
    #[zbus(property)]
    fn model(&self) -> zbus::Result<String>;

    /// Optical property
    #[zbus(property)]
    fn optical(&self) -> zbus::Result<bool>;

    /// OpticalBlank property
    #[zbus(property)]
    fn optical_blank(&self) -> zbus::Result<bool>;

    /// OpticalNumAudioTracks property
    #[zbus(property)]
    fn optical_num_audio_tracks(&self) -> zbus::Result<u32>;

    /// OpticalNumDataTracks property
    #[zbus(property)]
    fn optical_num_data_tracks(&self) -> zbus::Result<u32>;

    /// OpticalNumSessions property
    #[zbus(property)]
    fn optical_num_sessions(&self) -> zbus::Result<u32>;

    /// OpticalNumTracks property
    #[zbus(property)]
    fn optical_num_tracks(&self) -> zbus::Result<u32>;

    /// Removable property
    #[zbus(property)]
    fn removable(&self) -> zbus::Result<bool>;

    /// Revision property
    #[zbus(property)]
    fn revision(&self) -> zbus::Result<String>;

    /// RotationRate property
    #[zbus(property)]
    fn rotation_rate(&self) -> zbus::Result<i32>;

    /// Seat property
    #[zbus(property)]
    fn seat(&self) -> zbus::Result<String>;

    /// Serial property
    #[zbus(property)]
    fn serial(&self) -> zbus::Result<String>;

    /// SiblingId property
    #[zbus(property)]
    fn sibling_id(&self) -> zbus::Result<String>;

    /// Size property
    #[zbus(property)]
    fn size(&self) -> zbus::Result<u64>;

    /// SortKey property
    #[zbus(property)]
    fn sort_key(&self) -> zbus::Result<String>;

    /// TimeDetected property
    #[zbus(property)]
    fn time_detected(&self) -> zbus::Result<u64>;

    /// TimeMediaDetected property
    #[zbus(property)]
    fn time_media_detected(&self) -> zbus::Result<u64>;

    /// Vendor property
    #[zbus(property)]
    fn vendor(&self) -> zbus::Result<String>;

    /// WWN property
    #[zbus(property, name = "WWN")]
    fn wwn(&self) -> zbus::Result<String>;
}
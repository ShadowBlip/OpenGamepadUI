//! # D-Bus interface proxy for: `org.freedesktop.UDisks2.PartitionTable`
//!
//! This code was generated by `zbus-xmlgen` `4.1.0` from D-Bus introspection data.
//! Source: `Interface '/org/freedesktop/UDisks2/block_devices/xxxx' from service 'org.freedesktop.UDisks2' on system bus`.
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
    interface = "org.freedesktop.UDisks2.PartitionTable",
    default_service = "org.freedesktop.UDisks2"
)]
trait PartitionTable {
    /// CreatePartition method
    fn create_partition(
        &self,
        offset: u64,
        size: u64,
        type_: &str,
        name: &str,
        options: std::collections::HashMap<&str, &zbus::zvariant::Value<'_>>,
    ) -> zbus::Result<zbus::zvariant::OwnedObjectPath>;

    /// CreatePartitionAndFormat method
    #[allow(clippy::too_many_arguments)]
    fn create_partition_and_format(
        &self,
        offset: u64,
        size: u64,
        type_: &str,
        name: &str,
        options: std::collections::HashMap<&str, &zbus::zvariant::Value<'_>>,
        format_type: &str,
        format_options: std::collections::HashMap<&str, &zbus::zvariant::Value<'_>>,
    ) -> zbus::Result<zbus::zvariant::OwnedObjectPath>;

    /// Partitions property
    #[zbus(property)]
    fn partitions(&self) -> zbus::Result<Vec<zbus::zvariant::OwnedObjectPath>>;

    /// Type property
    #[zbus(property)]
    fn type_(&self) -> zbus::Result<String>;
}
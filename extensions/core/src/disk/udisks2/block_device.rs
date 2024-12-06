use byte_unit::{Byte, UnitType};
use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::udisks2::{
    block::BlockProxyBlocking, partition_table::PartitionTableProxyBlocking,
};
use crate::get_dbus_system_blocking;

use super::drive_device::DriveDevice;
use super::partition_device::PartitionDevice;
use super::UDISKS2_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct BlockDevice {
    base: Base<Resource>,
    conn: Option<zbus::blocking::Connection>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,

    #[allow(dead_code)]
    #[var(get = get_readable_size)]
    readable_size: GString,
}

#[godot_api]
impl BlockDevice {
    #[signal]
    fn updated();

    /// Create a new [BlockDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        log::debug!("BlockDevice created with path: {path}");

        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                dbus_path: path,
                readable_size: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the device
    fn get_proxy(&self) -> Option<BlockProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            let path: String = self.dbus_path.clone().into();
            BlockProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Return a proxy instance to the partition table dbus interface
    fn get_partition_table_proxy(&self) -> Option<PartitionTableProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            let path: String = self.dbus_path.clone().into();
            PartitionTableProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [BlockDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{UDISKS2_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<BlockDevice> = res.cast();
                device
            } else {
                let mut device = BlockDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = BlockDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Get all the partitions that this block device contains
    #[func]
    pub fn get_partitions(&self) -> Array<Gd<PartitionDevice>> {
        let mut all_partitions = array![];
        let Some(proxy) = self.get_partition_table_proxy() else {
            return array![];
        };

        let partitions = proxy.partitions().unwrap_or_default();
        for partition in partitions {
            let path = partition.as_str();
            let partition_device = PartitionDevice::new(path);
            all_partitions.push(&partition_device);
        }

        all_partitions
    }

    /// Return the parent DriveDevice for this BlockDevice
    #[func]
    pub fn get_drive(&self) -> Option<Gd<DriveDevice>> {
        let proxy = self.get_proxy()?;
        let drive = proxy.drive().ok()?;
        Some(DriveDevice::new(drive.as_str()))
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    /// Return the size type of the [BlockDevice] as a human readable String
    #[func]
    pub fn get_readable_size(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let size_bytes = proxy.size().unwrap_or(0);

        let size = Byte::from_u64(size_bytes).get_appropriate_unit(UnitType::Decimal);
        format!("{size:.2}").to_godot()
    }
}

impl Drop for BlockDevice {
    fn drop(&mut self) {
        log::trace!("BlockDevice '{}' is being destroyed!", self.dbus_path);
    }
}

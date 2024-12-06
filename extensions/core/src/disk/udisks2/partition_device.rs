use byte_unit::{Byte, UnitType};
use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::udisks2::{
    block::BlockProxyBlocking, filesystem::FilesystemProxyBlocking,
    partition::PartitionProxyBlocking,
};
use crate::get_dbus_system_blocking;

use super::filesystem_device::FilesystemDevice;
use super::UDISKS2_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct PartitionDevice {
    base: Base<Resource>,
    conn: Option<zbus::blocking::Connection>,

    #[allow(dead_code)]
    #[var(get = get_filesystem_type)]
    filesystem_type: GString,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,

    #[allow(dead_code)]
    #[var(get = get_partition_name)]
    partition_name: GString,

    #[allow(dead_code)]
    #[var(get = get_readable_size)]
    readable_size: GString,
}

#[godot_api]
impl PartitionDevice {
    #[signal]
    fn updated();

    /// Create a new [PartitionDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        log::debug!("PartitionDevice created with path: {path}");

        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                dbus_path: path,
                filesystem_type: Default::default(),
                partition_name: Default::default(),
                readable_size: Default::default(),
            }
        })
    }
    /// Return a proxy instance to the block device dbus interface
    fn get_block_proxy(&self) -> Option<BlockProxyBlocking> {
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

    /// Return a proxy instance to the partition dbus interface
    fn get_partition_proxy(&self) -> Option<PartitionProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            let path: String = self.dbus_path.clone().into();
            PartitionProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Return a proxy instance to the filesystem dbus interface
    fn get_filesystem_proxy(&self) -> Option<FilesystemProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            let path: String = self.dbus_path.clone().into();
            FilesystemProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [PartitionDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{UDISKS2_BUS}{path}/partition");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<PartitionDevice> = res.cast();
                device
            } else {
                let mut device = PartitionDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = PartitionDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Get all the partitions that this [BlockDevice] contains
    #[func]
    pub fn get_filesystem(&self) -> Option<Gd<FilesystemDevice>> {
        // Check if we have a filesystem dbus interface
        self.get_filesystem_proxy()?;

        // If we have one, return a filesystem device
        Some(FilesystemDevice::new(self.dbus_path.to_string().as_str()))
    }

    /// Return the DBus path to the [Partitiondevice]
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    /// Return the filesystem type of the [BlockDevice]
    #[func]
    pub fn get_filesystem_type(&self) -> GString {
        let Some(proxy) = self.get_block_proxy() else {
            return Default::default();
        };
        proxy.id_type().unwrap_or_default().to_godot()
    }

    /// Return the name of the [PartitionDevice]
    #[func]
    pub fn get_partition_name(&self) -> GString {
        let Some(proxy) = self.get_partition_proxy() else {
            return Default::default();
        };
        proxy.name().unwrap_or_default().to_godot()
    }

    /// Return the size type of the [PartitionDevice] as a human readable String
    #[func]
    pub fn get_readable_size(&self) -> GString {
        let Some(proxy) = self.get_partition_proxy() else {
            return Default::default();
        };
        let size_bytes = proxy.size().unwrap_or(0);

        let size = Byte::from_u64(size_bytes).get_appropriate_unit(UnitType::Decimal);
        format!("{size:.2}").to_godot()
    }
}

impl Drop for PartitionDevice {
    fn drop(&mut self) {
        log::trace!("PartitionDevice '{}' is being destroyed!", self.dbus_path);
    }
}

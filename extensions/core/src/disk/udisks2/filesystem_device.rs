use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::udisks2::filesystem::FilesystemProxyBlocking;
use crate::get_dbus_system_blocking;

use super::UDISKS2_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct FilesystemDevice {
    base: Base<Resource>,
    conn: Option<zbus::blocking::Connection>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
}

#[godot_api]
impl FilesystemDevice {
    #[signal]
    fn updated();

    /// Create a new [FilesystemDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        log::debug!("FilesystemDevice created with path: {path}");

        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                dbus_path: path,
            }
        })
    }

    /// Return a proxy instance to the device
    fn get_proxy(&self) -> Option<FilesystemProxyBlocking> {
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

    /// Get or create a [FilesystemDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{UDISKS2_BUS}{path}/filesystem");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<FilesystemDevice> = res.cast();
                device
            } else {
                let mut device = FilesystemDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = FilesystemDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Get all the mount points for this [FilesystemDevice]
    #[func]
    pub fn get_mounts(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let mut mount_points = PackedStringArray::new();
        let mount_points_bytes = proxy.mount_points().unwrap_or_default();
        for mount_point_bytes in mount_points_bytes {
            let mount_point = String::from_utf8_lossy(mount_point_bytes.as_slice());
            mount_points.push(mount_point.to_string().as_str());
        }

        mount_points
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }
}

impl Drop for FilesystemDevice {
    fn drop(&mut self) {
        log::trace!("FilesystemDevice '{}' is being destroyed!", self.dbus_path);
    }
}

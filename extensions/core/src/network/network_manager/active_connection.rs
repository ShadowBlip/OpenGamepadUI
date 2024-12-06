use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::networkmanager::active::ActiveProxyBlocking;
use crate::get_dbus_system_blocking;

use super::NETWORK_MANAGER_BUS;

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct NetworkActiveConnection {
    base: Base<Resource>,

    conn: Option<zbus::blocking::Connection>,
    path: String,

    /// The DBus path of the [NetworkActiveConnection]
    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    #[allow(dead_code)]
    #[var(get = get_state)]
    state: u32,
}

#[godot_api]
impl NetworkActiveConnection {
    /// the state of the connection is unknown
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_UNKNOWN: u32 = 0;
    /// a network connection is being prepared
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_ACTIVATING: u32 = 1;
    /// there is a connection to the network
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_ACTIVATED: u32 = 2;
    /// the network connection is being torn down and cleaned up
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_DEACTIVATING: u32 = 3;
    /// the network connection is disconnected and will be removed
    #[constant]
    const NM_ACTIVE_CONNECTION_STATE_DEACTIVATED: u32 = 4;

    /// Create a new [NetworkActiveConnection] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                path: path.clone().into(),
                dbus_path: path,
                state: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the network device
    fn get_proxy(&self) -> Option<ActiveProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            ActiveProxyBlocking::builder(conn)
                .path(self.path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [NetworkActiveConnection] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{NETWORK_MANAGER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<NetworkActiveConnection> = res.cast();
                device
            } else {
                let mut device = NetworkActiveConnection::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = NetworkActiveConnection::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    /// The state of this active connection.
    #[func]
    pub fn get_state(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.state().unwrap_or_default()
    }

    /// Dispatches signals
    pub fn process(&mut self) {}
}

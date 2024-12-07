use std::collections::HashMap;

use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};
use zvariant::ObjectPath;

use crate::dbus::networkmanager::access_point::{AccessPointProxy, AccessPointProxyBlocking};
use crate::dbus::networkmanager::network_manager::NetworkManagerProxyBlocking;
use crate::dbus::networkmanager::settings::SettingsProxyBlocking;
use crate::dbus::RunError;
use crate::{get_dbus_system, get_dbus_system_blocking, RUNTIME};
use futures_util::stream::StreamExt;
use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use super::active_connection::NetworkActiveConnection;
use super::device::NetworkDevice;
use super::NETWORK_MANAGER_BUS;

/// Signals that can be emitted by this resource
#[derive(Debug)]
enum Signal {
    PropertyStrengthChanged(u8),
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct NetworkAccessPoint {
    base: Base<Resource>,

    conn: Option<zbus::blocking::Connection>,
    rx: Receiver<Signal>,
    path: String,

    /// The DBus path of the [NetworkAccessPoint]
    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    /// The Service Set Identifier identifying the access point.
    #[allow(dead_code)]
    #[var(get = get_ssid)]
    ssid: GString,
    /// The current signal quality of the access point, in percent.
    #[allow(dead_code)]
    #[var(get = get_strength)]
    strength: u8,
    /// Flags describing the capabilities of the access point.
    #[allow(dead_code)]
    #[var(get = get_flags)]
    flags: u32,
    /// Flags describing the access point's capabilities according to WPA (Wifi Protected Access).
    #[allow(dead_code)]
    #[var(get = get_wpa_flags)]
    wpa_flags: u32,
    /// The radio channel frequency in use by the access point, in MHz.
    #[allow(dead_code)]
    #[var(get = get_frequency)]
    frequency: u32,
    /// The hardware address (BSSID) of the access point.
    #[allow(dead_code)]
    #[var(get = get_hardware_address)]
    hardware_address: GString,
    /// Describes the operating mode of the access point.
    #[allow(dead_code)]
    #[var(get = get_mode)]
    mode: u32,
    /// The maximum bitrate this access point is capable of, in kilobits/second (Kb/s).
    #[allow(dead_code)]
    #[var(get = get_max_bitrate)]
    max_bitrate: u32,
    /// The timestamp (in CLOCK_BOOTTIME seconds) for the last time the access point was found in scan results. A value of -1 means the access point has never been found in scan results.
    #[allow(dead_code)]
    #[var(get = get_last_seen)]
    last_seen: i32,
}

#[godot_api]
impl NetworkAccessPoint {
    /// access point has no special capabilities
    #[constant]
    const NM_802_11_AP_FLAGS_NONE: u32 = 0x00000000;
    /// access point requires authentication and encryption (usually means WEP)
    #[constant]
    const NM_802_11_AP_FLAGS_PRIVACY: u32 = 0x00000001;

    /// the access point has no special security requirements
    #[constant]
    const NM_802_11_AP_SEC_NONE: u32 = 0x00000000;
    /// 40/64-bit WEP is supported for pairwise/unicast encryption
    #[constant]
    const NM_802_11_AP_SEC_PAIR_WEP40: u32 = 0x00000001;
    /// 104/128-bit WEP is supported for pairwise/unicast encryption
    #[constant]
    const NM_802_11_AP_SEC_PAIR_WEP104: u32 = 0x00000002;
    /// TKIP is supported for pairwise/unicast encryption
    #[constant]
    const NM_802_11_AP_SEC_PAIR_TKIP: u32 = 0x00000004;
    /// AES/CCMP is supported for pairwise/unicast encryption
    #[constant]
    const NM_802_11_AP_SEC_PAIR_CCMP: u32 = 0x00000008;
    /// 40/64-bit WEP is supported for group/broadcast encryption
    #[constant]
    const NM_802_11_AP_SEC_GROUP_WEP40: u32 = 0x00000010;
    /// 104/128-bit WEP is supported for group/broadcast encryption
    #[constant]
    const NM_802_11_AP_SEC_GROUP_WEP104: u32 = 0x00000020;
    /// TKIP is supported for group/broadcast encryption
    #[constant]
    const NM_802_11_AP_SEC_GROUP_TKIP: u32 = 0x00000040;
    /// AES/CCMP is supported for group/broadcast encryption
    #[constant]
    const NM_802_11_AP_SEC_GROUP_CCMP: u32 = 0x00000080;
    /// WPA/RSN Pre-Shared Key encryption is supported
    #[constant]
    const NM_802_11_AP_SEC_KEY_MGMT_PSK: u32 = 0x00000100;
    /// 802.1x authentication and key management is supported
    #[constant]
    const NM_802_11_AP_SEC_KEY_MGMT_802_1X: u32 = 0x00000200;

    /// the device or access point mode is unknown
    #[constant]
    const NM_802_11_MODE_UNKNOWN: u32 = 0;
    /// for both devices and access point objects, indicates the object is part of an Ad-Hoc 802.11 network without a central coordinating access point.
    #[constant]
    const NM_802_11_MODE_ADHOC: u32 = 1;
    /// the device or access point is in infrastructure mode. For devices, this indicates the device is an 802.11 client/station. For access point objects, this indicates the object is an access point that provides connectivity to clients.
    #[constant]
    const NM_802_11_MODE_INFRA: u32 = 2;
    /// the device is an access point/hotspot. Not valid for access point objects; used only for hotspot mode on the local machine.
    #[constant]
    const NM_802_11_MODE_AP: u32 = 3;

    /// Emitted whenever the connection strength changes
    #[signal]
    fn strength_changed(strength: u8);

    /// Create a new [NetworkAccessPoint] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Create a channel to communicate with the service
            let (tx, rx) = channel();

            // Spawn a task using the shared tokio runtime to listen for signals
            let dbus_path = path.to_string();
            RUNTIME.spawn(async move {
                if let Err(e) = run(dbus_path, tx).await {
                    log::error!("Failed to run AccessPoint task: ${e:?}");
                }
            });

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                conn,
                rx,
                path: path.clone().into(),
                dbus_path: path,
                ssid: Default::default(),
                strength: Default::default(),
                flags: Default::default(),
                wpa_flags: Default::default(),
                frequency: Default::default(),
                hardware_address: Default::default(),
                mode: Default::default(),
                max_bitrate: Default::default(),
                last_seen: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the network device
    fn get_proxy(&self) -> Option<AccessPointProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            AccessPointProxyBlocking::builder(conn)
                .path(self.path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Return a proxy instance to the settings interface
    fn get_settings_proxy(&self) -> Option<SettingsProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            SettingsProxyBlocking::builder(conn).build().ok()
        } else {
            None
        }
    }

    /// Return a proxy instance to the network manager interface
    fn get_manager_proxy(&self) -> Option<NetworkManagerProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            NetworkManagerProxyBlocking::builder(conn).build().ok()
        } else {
            None
        }
    }

    /// Get or create a [NetworkAccessPoint] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{NETWORK_MANAGER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<NetworkAccessPoint> = res.cast();
                device
            } else {
                let mut device = NetworkAccessPoint::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = NetworkAccessPoint::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    /// Start connecting to the access point with the given password.
    #[func]
    pub fn connect(
        &self,
        device: Gd<NetworkDevice>,
        password: GString,
    ) -> Option<Gd<NetworkActiveConnection>> {
        let Some(settings) = self.get_settings_proxy() else {
            log::warn!("Unable to connect; settings not found");
            return None;
        };
        let Some(network_manager) = self.get_manager_proxy() else {
            log::warn!("Unable to connect; network manager not found");
            return None;
        };
        let ssid = self.get_ssid().to_string();
        if ssid.is_empty() {
            log::warn!("SSID is empty; unable to connect");
            return None;
        }

        // Build the connection settings
        let mut connection = HashMap::new();
        let mut conn = HashMap::new();
        let conn_type = zvariant::Value::from("802-11-wireless");
        conn.insert("type", &conn_type);
        let id = zvariant::Value::from(ssid.clone());
        conn.insert("id", &id);
        connection.insert("connection", conn);

        let mut wireless = HashMap::new();
        let wireless_ssid = zvariant::Value::from(ssid.as_bytes());
        wireless.insert("ssid", &wireless_ssid);
        connection.insert("802-11-wireless", wireless);

        let key_mgmt = zvariant::Value::from("wpa-psk");
        let psk = zvariant::Value::from(password.to_string());
        if !password.is_empty() {
            let mut security = HashMap::new();
            security.insert("key-mgmt", &key_mgmt);
            security.insert("psk", &psk);

            connection.insert("802-11-wireless-security", security);
        }

        // Add the connection
        let connection_path = match settings.add_connection(connection) {
            Ok(conn_path) => conn_path,
            Err(e) => {
                log::warn!("Unable to add new connection: {e:?}");
                return None;
            }
        };

        let connection_path = ObjectPath::from(connection_path);
        let device_path = match ObjectPath::try_from(device.bind().get_dbus_path().to_string()) {
            Ok(path) => path,
            Err(e) => {
                log::warn!("Invalid device path: {e:?}");
                return None;
            }
        };
        let ap_path = match ObjectPath::try_from(self.dbus_path.to_string()) {
            Ok(path) => path,
            Err(e) => {
                log::warn!("Invalid access point path: {e:?}");
                return None;
            }
        };

        // Activate the connection
        let active_connection_path =
            match network_manager.activate_connection(&connection_path, &device_path, &ap_path) {
                Ok(active_connection_path) => active_connection_path,
                Err(e) => {
                    log::warn!("Failed to activate connection: {e:?}");
                    return None;
                }
            };
        if active_connection_path.is_empty() {
            return None;
        }

        Some(NetworkActiveConnection::new(
            active_connection_path.as_str(),
        ))
    }

    /// The Service Set Identifier identifying the access point.
    #[func]
    pub fn get_ssid(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let value = proxy.ssid().unwrap_or_default();
        String::from_utf8_lossy(value.as_slice()).to_string().into()
    }

    /// The current signal quality of the access point, in percent.
    #[func]
    pub fn get_strength(&self) -> u8 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.strength().unwrap_or_default()
    }

    /// Flags describing the capabilities of the access point.
    #[func]
    pub fn get_flags(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.flags().unwrap_or_default()
    }

    /// Flags describing the access point's capabilities according to WPA (Wifi Protected Access).
    #[func]
    pub fn get_wpa_flags(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.wpa_flags().unwrap_or_default()
    }

    /// The radio channel frequency in use by the access point, in MHz.
    #[func]
    pub fn get_frequency(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.frequency().unwrap_or_default()
    }

    /// The hardware address (BSSID) of the access point.
    #[func]
    pub fn get_hardware_address(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.hw_address().unwrap_or_default().into()
    }

    /// Describes the operating mode of the access point.
    #[func]
    pub fn get_mode(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.mode().unwrap_or_default()
    }

    /// The maximum bitrate this access point is capable of, in kilobits/second (Kb/s).
    #[func]
    pub fn get_max_bitrate(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.max_bitrate().unwrap_or_default()
    }

    /// The timestamp (in CLOCK_BOOTTIME seconds) for the last time the access point was found in scan results. A value of -1 means the access point has never been found in scan results.
    #[func]
    pub fn get_last_seen(&self) -> i32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.last_seen().unwrap_or_default()
    }

    /// Process signals and emit them as Godot signals.
    pub fn process(&mut self) {
        // Drain all messages from the channel to process them
        loop {
            let signal = match self.rx.try_recv() {
                Ok(value) => value,
                Err(e) => match e {
                    TryRecvError::Empty => break,
                    TryRecvError::Disconnected => {
                        log::error!("Backend thread is not running!");
                        return;
                    }
                },
            };
            self.process_signal(signal);
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::PropertyStrengthChanged(value) => {
                self.base_mut()
                    .emit_signal("strength_changed", &[value.to_variant()]);
            }
        }
    }
}

/// Runs NetworkAccessPoint tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(path: String, tx: Sender<Signal>) -> Result<(), RunError> {
    log::debug!("Spawning access point task for {path}");
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;

    // Get a proxy instance to the device
    let connection = AccessPointProxy::builder(&conn).path(path)?.build().await?;

    // Spawn a task to listen for property changes
    let mut state_changed = connection.receive_strength_changed().await;
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        loop {
            tokio::select! {
                signal = state_changed.next() => {
                    let Some(signal) = signal else {
                        break;
                    };
                    let value = signal.get().await.unwrap_or_default();
                    let signal = Signal::PropertyStrengthChanged(value);
                    if signals_tx.send(signal).is_err() {
                        break;
                    }
                }
            }
        }
    });

    Ok(())
}

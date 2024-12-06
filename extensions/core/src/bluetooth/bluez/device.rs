use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use futures_util::StreamExt;
use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};

use crate::dbus::bluez::device1::{Device1Proxy, Device1ProxyBlocking};
use crate::dbus::RunError;
use crate::{get_dbus_system, get_dbus_system_blocking, RUNTIME};

use super::BLUEZ_BUS;

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Updated,
    ConnectedChanged { value: bool },
    PairedChanged { value: bool },
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct BluetoothDevice {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
    #[allow(dead_code)]
    #[var(get = get_adapter)]
    adapter: GString,
    #[allow(dead_code)]
    #[var(get = get_address)]
    address: GString,
    #[allow(dead_code)]
    #[var(get = get_address_type)]
    address_type: GString,
    #[allow(dead_code)]
    #[var(get = get_alias, set = set_alias)]
    alias: GString,
    #[allow(dead_code)]
    #[var(get = get_appearance)]
    appearance: u16,
    #[allow(dead_code)]
    #[var(get = get_blocked, set = set_blocked)]
    blocked: bool,
    #[allow(dead_code)]
    #[var(get = get_bonded)]
    bonded: bool,
    #[allow(dead_code)]
    #[var(get = get_class)]
    class: u32,
    #[allow(dead_code)]
    #[var(get = get_connected)]
    connected: bool,
    #[allow(dead_code)]
    #[var(get = get_icon)]
    icon: GString,
    #[allow(dead_code)]
    #[var(get = get_legacy_pairing)]
    legacy_pairing: bool,
    #[allow(dead_code)]
    #[var(get = get_modalias)]
    modalias: GString,
    #[allow(dead_code)]
    #[var(get = get_name)]
    name: GString,
    #[allow(dead_code)]
    #[var(get = get_paired)]
    paired: bool,
    #[allow(dead_code)]
    #[var(get = get_rssi)]
    rssi: i16,
    #[allow(dead_code)]
    #[var(get = get_services_resolved)]
    services_resolved: bool,
    #[allow(dead_code)]
    #[var(get = get_trusted, set = set_trusted)]
    trusted: bool,
    #[allow(dead_code)]
    #[var(get = get_tx_power)]
    tx_power: i16,
    #[allow(dead_code)]
    #[var(get = get_uuids)]
    uuids: PackedStringArray,
    #[allow(dead_code)]
    #[var(get = get_wake_allowed, set = set_wake_allowed)]
    wake_allowed: bool,
}

#[godot_api]
impl BluetoothDevice {
    #[signal]
    fn updated();

    #[signal]
    fn connected_changed(value: bool);

    #[signal]
    fn paired_changed(value: bool);

    /// Create a new [BluetoothDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        log::debug!("BluetoothDevice created with path: {path}");
        let (tx, rx) = channel();
        let dbus_path = path.clone().into();

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx, dbus_path).await {
                log::error!("Failed to run BluetoothDevice task: ${e:?}");
            }
        });

        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                rx,
                conn,
                dbus_path: path,
                adapter: Default::default(),
                address: Default::default(),
                address_type: Default::default(),
                alias: Default::default(),
                appearance: Default::default(),
                blocked: Default::default(),
                bonded: Default::default(),
                class: Default::default(),
                connected: Default::default(),
                icon: Default::default(),
                legacy_pairing: Default::default(),
                modalias: Default::default(),
                name: Default::default(),
                paired: Default::default(),
                rssi: Default::default(),
                services_resolved: Default::default(),
                trusted: Default::default(),
                tx_power: Default::default(),
                uuids: Default::default(),
                wake_allowed: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the device
    fn get_proxy(&self) -> Option<Device1ProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            let path: String = self.dbus_path.clone().into();
            Device1ProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [BluetoothDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{BLUEZ_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<BluetoothDevice> = res.cast();
                device
            } else {
                let mut device = BluetoothDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = BluetoothDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the device
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    #[func]
    pub fn cancel_pairing(&self) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.cancel_pairing().unwrap_or_default()
    }

    #[func]
    pub fn connect_to(&self) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.connect().unwrap_or_default()
    }

    #[func]
    pub fn connect_to_profile(&self, uuid: GString) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let uuid = uuid.to_string();
        proxy.connect_profile(uuid.as_str()).unwrap_or_default()
    }

    #[func]
    pub fn disconnect_from(&self) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.disconnect().unwrap_or_default()
    }

    #[func]
    pub fn disconnect_from_profile(&self, uuid: GString) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let uuid = uuid.to_string();
        proxy.disconnect_profile(uuid.as_str()).unwrap_or_default()
    }

    #[func]
    pub fn pair(&self) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.pair().unwrap_or_default()
    }

    #[func]
    pub fn get_wake_allowed(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.wake_allowed().unwrap_or_default()
    }

    #[func]
    pub fn set_wake_allowed(&self, allowed: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_wake_allowed(allowed).unwrap_or_default()
    }

    #[func]
    pub fn get_uuids(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let values: Vec<GString> = proxy
            .uuids()
            .unwrap_or_default()
            .into_iter()
            .map(|v| v.to_godot())
            .collect();
        values.into()
    }

    #[func]
    pub fn get_tx_power(&self) -> i16 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.tx_power().unwrap_or_default()
    }

    #[func]
    pub fn get_trusted(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.trusted().unwrap_or_default()
    }

    #[func]
    pub fn set_trusted(&self, value: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_trusted(value).unwrap_or_default()
    }

    #[func]
    pub fn get_services_resolved(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.services_resolved().unwrap_or_default()
    }

    #[func]
    pub fn get_rssi(&self) -> i16 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.rssi().unwrap_or_default()
    }

    #[func]
    pub fn get_paired(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.paired().unwrap_or_default()
    }

    #[func]
    pub fn get_name(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.name().unwrap_or_default().into()
    }

    #[func]
    pub fn get_modalias(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.modalias().unwrap_or_default().into()
    }

    #[func]
    pub fn get_legacy_pairing(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.legacy_pairing().unwrap_or_default()
    }

    #[func]
    pub fn get_icon(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.icon().unwrap_or_default().into()
    }

    #[func]
    pub fn get_connected(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.connected().unwrap_or_default()
    }

    #[func]
    pub fn get_class(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.class().unwrap_or_default()
    }

    #[func]
    pub fn get_bonded(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.bonded().unwrap_or_default()
    }

    #[func]
    pub fn get_blocked(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.blocked().unwrap_or_default()
    }

    #[func]
    pub fn set_blocked(&self, value: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_blocked(value).unwrap_or_default()
    }

    #[func]
    pub fn get_appearance(&self) -> u16 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.appearance().unwrap_or_default()
    }

    #[func]
    pub fn get_alias(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.alias().unwrap_or_default().into()
    }

    #[func]
    pub fn set_alias(&self, value: GString) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy
            .set_alias(value.to_string().as_str())
            .unwrap_or_default()
    }

    #[func]
    pub fn get_address_type(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.address_type().unwrap_or_default().into()
    }

    #[func]
    pub fn get_address(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.address().unwrap_or_default().into()
    }

    #[func]
    pub fn get_adapter(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.adapter().unwrap_or_default().to_string().into()
    }

    /// Dispatches signals
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
        log::trace!("Got signal: {signal:?}");
        match signal {
            Signal::Updated => {
                self.base_mut().emit_signal("updated", &[]);
            }
            Signal::ConnectedChanged { value } => {
                self.base_mut()
                    .emit_signal("connected_changed", &[value.to_variant()]);
            }
            Signal::PairedChanged { value } => {
                self.base_mut()
                    .emit_signal("paired_changed", &[value.to_variant()]);
            }
        }
    }
}

impl Drop for BluetoothDevice {
    fn drop(&mut self) {
        log::trace!("BluetoothDevice '{}' is being destroyed!", self.dbus_path);
    }
}

/// Run the signals task
async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;
    let proxy = Device1Proxy::builder(&conn).path(path)?.build().await?;

    let signals_tx = tx.clone();
    let mut events = proxy.receive_connected_changed().await;
    RUNTIME.spawn(async move {
        while let Some(event) = events.next().await {
            let value = event.get().await.unwrap_or_default();
            let signal = Signal::ConnectedChanged { value };
            if signals_tx.send(signal).is_err() {
                break;
            }
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_paired_changed().await;
    RUNTIME.spawn(async move {
        while let Some(event) = events.next().await {
            let value = event.get().await.unwrap_or_default();
            let signal = Signal::PairedChanged { value };
            if signals_tx.send(signal).is_err() {
                break;
            }
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    Ok(())
}

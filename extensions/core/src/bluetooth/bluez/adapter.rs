use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use futures_util::StreamExt;
use godot::obj::WithBaseField;
use godot::prelude::*;

use godot::classes::{Resource, ResourceLoader};
use zvariant::ObjectPath;

use crate::dbus::bluez::adapter1::{Adapter1Proxy, Adapter1ProxyBlocking};
use crate::dbus::RunError;
use crate::{get_dbus_system, get_dbus_system_blocking, RUNTIME};

use super::device::BluetoothDevice;
use super::BLUEZ_BUS;

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Discoverable { value: bool },
    Discovering { value: bool },
    Pairable { value: bool },
    Powered { value: bool },
    PowerState { value: String },
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct BluetoothAdapter {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,

    #[allow(dead_code)]
    #[var(get = get_dbus_path)]
    dbus_path: GString,
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
    #[var(get = get_class)]
    class: u32,
    #[allow(dead_code)]
    #[var(get = get_discoverable, set = set_discoverable)]
    discoverable: bool,
    #[allow(dead_code)]
    #[var(get = get_discoverable_timeout, set = set_discoverable_timeout)]
    discoverable_timeout: u32,
    #[allow(dead_code)]
    #[var(get = get_discovering)]
    discovering: bool,
    #[allow(dead_code)]
    #[var(get = get_experimental_features)]
    experimental_features: PackedStringArray,
    #[allow(dead_code)]
    #[var(get = get_manufacturer)]
    manufacturer: u16,
    #[allow(dead_code)]
    #[var(get = get_modalias)]
    modalias: GString,
    #[allow(dead_code)]
    #[var(get = get_name)]
    name: GString,
    #[allow(dead_code)]
    #[var(get = get_pairable, set = set_pairable)]
    pairable: bool,
    #[allow(dead_code)]
    #[var(get = get_pairable_timeout, set = set_pairable_timeout)]
    pairable_timeout: u32,
    #[allow(dead_code)]
    #[var(get = get_power_state)]
    power_state: GString,
    #[allow(dead_code)]
    #[var(get = get_powered, set = set_powered)]
    powered: bool,
    #[allow(dead_code)]
    #[var(get = get_roles)]
    roles: PackedStringArray,
    #[allow(dead_code)]
    #[var(get = get_uuids)]
    uuids: PackedStringArray,
    #[allow(dead_code)]
    #[var(get = get_version)]
    version: u8,
}

#[godot_api]
impl BluetoothAdapter {
    #[signal]
    fn discoverable_changed(value: bool);

    #[signal]
    fn discovering_changed(value: bool);

    #[signal]
    fn pairable_changed(value: bool);

    #[signal]
    fn powered_changed(value: bool);

    #[signal]
    fn power_state_changed(value: GString);

    /// Create a new [BluetoothAdapter] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        log::debug!("BluetoothAdapter created with path: {path}");
        let (tx, rx) = channel();
        let dbus_path = path.clone().into();

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx, dbus_path).await {
                log::error!("Failed to run DBusDevice task: ${e:?}");
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
                address: Default::default(),
                address_type: Default::default(),
                alias: Default::default(),
                class: Default::default(),
                discoverable: Default::default(),
                discoverable_timeout: Default::default(),
                discovering: Default::default(),
                experimental_features: Default::default(),
                manufacturer: Default::default(),
                modalias: Default::default(),
                name: Default::default(),
                pairable: Default::default(),
                pairable_timeout: Default::default(),
                power_state: Default::default(),
                powered: Default::default(),
                roles: Default::default(),
                uuids: Default::default(),
                version: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the adapter
    fn get_proxy(&self) -> Option<Adapter1ProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            let path: String = self.dbus_path.clone().into();
            Adapter1ProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [BluetoothAdapter] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{BLUEZ_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<BluetoothAdapter> = res.cast();
                device
            } else {
                let mut device = BluetoothAdapter::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = BluetoothAdapter::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Returns the DBus path to the [BluetoothAdapter]
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone()
    }

    #[func]
    pub fn get_address(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.address().unwrap_or_default().into()
    }

    #[func]
    pub fn get_address_type(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.address_type().unwrap_or_default().into()
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
    pub fn get_class(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.class().unwrap_or_default()
    }

    #[func]
    pub fn get_discoverable(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.discoverable().unwrap_or_default()
    }

    #[func]
    pub fn set_discoverable(&self, value: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_discoverable(value).unwrap_or_default()
    }

    #[func]
    pub fn get_discoverable_timeout(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.discoverable_timeout().unwrap_or_default()
    }

    #[func]
    pub fn set_discoverable_timeout(&self, value: u32) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_discoverable_timeout(value).unwrap_or_default()
    }

    #[func]
    pub fn get_discovering(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.discovering().unwrap_or_default()
    }

    #[func]
    pub fn get_experimental_features(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let values: Vec<GString> = proxy
            .experimental_features()
            .unwrap_or_default()
            .into_iter()
            .map(|v| v.to_godot())
            .collect();
        values.into()
    }

    #[func]
    pub fn get_manufacturer(&self) -> u16 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.manufacturer().unwrap_or_default()
    }

    #[func]
    pub fn get_modalias(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.modalias().unwrap_or_default().into()
    }

    #[func]
    pub fn get_name(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.name().unwrap_or_default().into()
    }

    #[func]
    pub fn get_pairable(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.pairable().unwrap_or_default()
    }

    #[func]
    pub fn set_pairable(&self, value: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_pairable(value).unwrap_or_default()
    }

    #[func]
    pub fn get_pairable_timeout(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.pairable_timeout().unwrap_or_default()
    }

    #[func]
    pub fn set_pairable_timeout(&self, value: u32) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_pairable_timeout(value).unwrap_or_default()
    }

    #[func]
    pub fn get_power_state(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.power_state().unwrap_or_default().into()
    }

    #[func]
    pub fn get_powered(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.powered().unwrap_or_default()
    }

    #[func]
    pub fn set_powered(&self, value: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_powered(value).unwrap_or_default()
    }

    #[func]
    pub fn get_roles(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let values: Vec<GString> = proxy
            .roles()
            .unwrap_or_default()
            .into_iter()
            .map(|v| v.to_godot())
            .collect();
        values.into()
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
    pub fn get_version(&self) -> u8 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.version().unwrap_or_default()
    }

    #[func]
    pub fn get_discovery_filters(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let filters: Vec<GString> = proxy
            .get_discovery_filters()
            .unwrap_or_default()
            .into_iter()
            .map(|v| v.to_godot())
            .collect();
        filters.into()
    }

    #[func]
    pub fn remove_device(&self, device: Gd<BluetoothDevice>) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        let path = device.bind().get_dbus_path().to_string();
        let path = ObjectPath::try_from(path).unwrap_or_default();
        proxy.remove_device(&path).unwrap_or_default()
    }

    #[func]
    pub fn start_discovery(&self) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        proxy.start_discovery().unwrap_or_default()
    }

    #[func]
    pub fn stop_discovery(&self) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        proxy.stop_discovery().unwrap_or_default()
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
        match signal {
            Signal::Discoverable { value } => {
                self.base_mut()
                    .emit_signal("discoverable_changed", &[value.to_variant()]);
            }
            Signal::Discovering { value } => {
                self.base_mut()
                    .emit_signal("discovering_changed", &[value.to_variant()]);
            }
            Signal::Pairable { value } => {
                self.base_mut()
                    .emit_signal("pairable_changed", &[value.to_variant()]);
            }
            Signal::Powered { value } => {
                self.base_mut()
                    .emit_signal("powered_changed", &[value.to_variant()]);
            }
            Signal::PowerState { value } => {
                self.base_mut()
                    .emit_signal("power_state_changed", &[value.to_variant()]);
            }
        }
    }
}

impl Drop for BluetoothAdapter {
    fn drop(&mut self) {
        log::trace!("BluetoothAdapter '{}' is being destroyed!", self.dbus_path);
    }
}

/// Run the signals task
async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;
    let proxy = Adapter1Proxy::builder(&conn).path(path)?.build().await?;

    let signals_tx = tx.clone();
    let mut events = proxy.receive_discoverable_changed().await;
    RUNTIME.spawn(async move {
        while let Some(event) = events.next().await {
            let value = event.get().await.unwrap_or_default();
            let signal = Signal::Discoverable { value };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_discovering_changed().await;
    RUNTIME.spawn(async move {
        while let Some(event) = events.next().await {
            let value = event.get().await.unwrap_or_default();
            let signal = Signal::Discovering { value };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_pairable_changed().await;
    RUNTIME.spawn(async move {
        while let Some(event) = events.next().await {
            let value = event.get().await.unwrap_or_default();
            let signal = Signal::Pairable { value };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_powered_changed().await;
    RUNTIME.spawn(async move {
        while let Some(event) = events.next().await {
            let value = event.get().await.unwrap_or_default();
            let signal = Signal::Powered { value };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_power_state_changed().await;
    RUNTIME.spawn(async move {
        while let Some(event) = events.next().await {
            let value = event.get().await.unwrap_or_default();
            let signal = Signal::PowerState { value };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    Ok(())
}

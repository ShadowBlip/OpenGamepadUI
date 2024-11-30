use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};

use futures_util::StreamExt;
use godot::{classes::ResourceLoader, prelude::*};

use crate::{
    dbus::{
        upower::device::{DeviceProxy, DeviceProxyBlocking},
        RunError,
    },
    get_dbus_system, get_dbus_system_blocking, RUNTIME,
};

use super::upower::UPOWER_BUS;

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Updated,
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct UPowerDevice {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,
    #[var]
    dbus_path: GString,
    #[allow(dead_code)]
    #[var(get = get_battery_level)]
    battery_level: u32,
    #[allow(dead_code)]
    #[var(get = get_charge_cycles)]
    charge_cycles: i32,
    #[allow(dead_code)]
    #[var(get = get_energy)]
    energy: f64,
    #[allow(dead_code)]
    #[var(get = get_energy_empty)]
    energy_empty: f64,
    #[allow(dead_code)]
    #[var(get = get_energy_full)]
    energy_full: f64,
    #[allow(dead_code)]
    #[var(get = get_energy_full_design)]
    energy_full_design: f64,
    #[allow(dead_code)]
    #[var(get = get_energy_rate)]
    energy_rate: f64,
    #[allow(dead_code)]
    #[var(get = get_has_history)]
    has_history: bool,
    #[allow(dead_code)]
    #[var(get = get_has_statistics)]
    has_statistics: bool,
    #[allow(dead_code)]
    #[var(get = get_icon_name)]
    icon_name: GString,
    #[allow(dead_code)]
    #[var(get = get_is_present)]
    is_present: bool,
    #[allow(dead_code)]
    #[var(get = get_is_rechargeable)]
    is_rechargeable: bool,
    #[allow(dead_code)]
    #[var(get = get_luminosity)]
    luminosity: f64,
    #[allow(dead_code)]
    #[var(get = get_model)]
    model: GString,
    #[allow(dead_code)]
    #[var(get = get_native_path)]
    native_path: GString,
    #[allow(dead_code)]
    #[var(get = get_online)]
    online: bool,
    #[allow(dead_code)]
    #[var(get = get_percentage)]
    percentage: f64,
    #[allow(dead_code)]
    #[var(get = get_power_supply)]
    power_supply: bool,
    #[allow(dead_code)]
    #[var(get = get_serial)]
    serial: GString,
    #[allow(dead_code)]
    #[var(get = get_state)]
    state: u32,
    #[allow(dead_code)]
    #[var(get = get_technology)]
    technology: u32,
    #[allow(dead_code)]
    #[var(get = get_temperature)]
    temperature: f64,
    #[allow(dead_code)]
    #[var(get = get_time_to_empty)]
    time_to_empty: i64,
    #[allow(dead_code)]
    #[var(get = get_time_to_full)]
    time_to_full: i64,
    #[allow(dead_code)]
    #[var(get = get_type)]
    type_: u32,
    #[allow(dead_code)]
    #[var(get = get_update_time)]
    update_time: i64,
    #[allow(dead_code)]
    #[var(get = get_vendor)]
    vendor: GString,
    #[allow(dead_code)]
    #[var(get = get_voltage)]
    voltage: f64,
    #[allow(dead_code)]
    #[var(get = get_warning_level)]
    warning_level: u32,
}

#[godot_api]
impl UPowerDevice {
    #[constant]
    const TYPE_UNKNOWN: i32 = 0;
    #[constant]
    const TYPE_LINE_POWER: i32 = 1;
    #[constant]
    const TYPE_BATTERY: i32 = 2;
    #[constant]
    const TYPE_UPS: i32 = 3;
    #[constant]
    const TYPE_MONITOR: i32 = 4;
    #[constant]
    const TYPE_MOUSE: i32 = 5;
    #[constant]
    const TYPE_KEYBOARD: i32 = 6;
    #[constant]
    const TYPE_PDA: i32 = 7;
    #[constant]
    const TYPE_PHONE: i32 = 8;
    #[constant]
    const TYPE_MEDIA_PLAYER: i32 = 9;
    #[constant]
    const TYPE_TABLET: i32 = 10;
    #[constant]
    const TYPE_COMPUTER: i32 = 11;
    #[constant]
    const TYPE_GAMING_INPUT: i32 = 12;
    #[constant]
    const TYPE_PEN: i32 = 13;
    #[constant]
    const TYPE_TOUCHPAD: i32 = 14;
    #[constant]
    const TYPE_MODEM: i32 = 15;
    #[constant]
    const TYPE_NETWORK: i32 = 16;
    #[constant]
    const TYPE_HEADSET: i32 = 17;
    #[constant]
    const TYPE_SPEAKERS: i32 = 18;
    #[constant]
    const TYPE_HEADPHONES: i32 = 19;
    #[constant]
    const TYPE_VIDEO: i32 = 20;
    #[constant]
    const TYPE_OTHER_AUDIO: i32 = 21;
    #[constant]
    const TYPE_REMOTE_CONTROL: i32 = 22;
    #[constant]
    const TYPE_PRINTER: i32 = 23;
    #[constant]
    const TYPE_SCANNER: i32 = 24;
    #[constant]
    const TYPE_CAMERA: i32 = 25;
    #[constant]
    const TYPE_WEARABLE: i32 = 26;
    #[constant]
    const TYPE_TOY: i32 = 27;
    #[constant]
    const TYPE_BLUETOOTH_GENREIC: i32 = 28;

    #[constant]
    const STATE_UNKNOWN: i32 = 0;
    #[constant]
    const STATE_CHARGING: i32 = 1;
    #[constant]
    const STATE_DISCHARGING: i32 = 2;
    #[constant]
    const STATE_EMPTY: i32 = 3;
    #[constant]
    const STATE_FULLY_CHARGED: i32 = 4;
    #[constant]
    const STATE_PENDING_CHARGE: i32 = 5;
    #[constant]
    const STATE_PENDING_DISCHARGE: i32 = 6;

    #[constant]
    const TECHNOLOGY_UNKNOWN: i32 = 0;
    #[constant]
    const TECHNOLOGY_LITHIUM_ION: i32 = 1;
    #[constant]
    const TECHNOLOGY_LITHIUM_POLYMER: i32 = 2;
    #[constant]
    const TECHNOLOGY_LITHIUM_IRON_PHOSPHATE: i32 = 3;
    #[constant]
    const TECHNOLOGY_LEAD_ACID: i32 = 4;
    #[constant]
    const TECHNOLOGY_NICKEL_CADMIUM: i32 = 5;
    #[constant]
    const TECHNOLOGY_NICKEL_METAL_HYDRIDE: i32 = 6;

    #[constant]
    const WARNING_LEVEL_UNKNOWN: i32 = 0;
    #[constant]
    const WARNING_LEVEL_NONE: i32 = 1;
    #[constant]
    const WARNING_LEVEL_DISCHARGING: i32 = 2;
    #[constant]
    const WARNING_LEVEL_LOW: i32 = 3;
    #[constant]
    const WARNING_LEVEL_CRITICAL: i32 = 4;
    #[constant]
    const WARNING_LEVEL_ACTION: i32 = 5;

    #[constant]
    const BATTERY_LEVEL_UNKNOWN: i32 = 0;
    #[constant]
    const BATTERY_LEVEL_NONE: i32 = 1;
    #[constant]
    const BATTERY_LEVEL_LOW: i32 = 3;
    #[constant]
    const BATTERY_LEVEL_CRITICAL: i32 = 4;
    #[constant]
    const BATTERY_LEVEL_NORMAL: i32 = 6;
    #[constant]
    const BATTERY_LEVEL_HIGH: i32 = 7;
    #[constant]
    const BATTERY_LEVEL_FULL: i32 = 8;

    #[signal]
    fn updated();

    /// Create a new [UPowerDevice] with the given DBus path
    pub fn from_path(path: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        let (tx, rx) = channel();
        let dbus_path = path.clone().into();

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx, dbus_path).await {
                log::error!("Failed to run UPowerDevice task: ${e:?}");
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
                battery_level: Default::default(),
                charge_cycles: Default::default(),
                energy: Default::default(),
                energy_empty: Default::default(),
                energy_full: Default::default(),
                energy_full_design: Default::default(),
                energy_rate: Default::default(),
                has_history: Default::default(),
                has_statistics: Default::default(),
                icon_name: Default::default(),
                is_present: Default::default(),
                is_rechargeable: Default::default(),
                luminosity: Default::default(),
                model: Default::default(),
                native_path: Default::default(),
                online: Default::default(),
                percentage: Default::default(),
                power_supply: Default::default(),
                serial: Default::default(),
                state: Default::default(),
                technology: Default::default(),
                temperature: Default::default(),
                time_to_empty: Default::default(),
                time_to_full: Default::default(),
                type_: Default::default(),
                update_time: Default::default(),
                vendor: Default::default(),
                voltage: Default::default(),
                warning_level: Default::default(),
            }
        })
    }

    /// Return a proxy instance to the device
    fn get_proxy(&self) -> Option<DeviceProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            let path: String = self.dbus_path.clone().into();
            DeviceProxyBlocking::builder(conn)
                .path(path)
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [UPowerDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{UPOWER_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists, loading that instead");
                let device: Gd<UPowerDevice> = res.cast();
                device
            } else {
                let mut device = UPowerDevice::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = UPowerDevice::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    #[func]
    pub fn get_battery_level(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.battery_level().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_charge_cycles(&self) -> i32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.charge_cycles().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_energy(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.energy().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_energy_empty(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.energy_empty().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_energy_full(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.energy_full().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_energy_full_design(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.energy_full_design().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_energy_rate(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.energy_rate().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_has_history(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.has_history().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_has_statistics(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.has_statistics().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_icon_name(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.icon_name().ok().unwrap_or_default().into()
    }

    #[func]
    pub fn get_is_present(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.is_present().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_is_rechargeable(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.is_rechargeable().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_luminosity(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.luminosity().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_model(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.model().ok().unwrap_or_default().into()
    }

    #[func]
    pub fn get_native_path(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.native_path().ok().unwrap_or_default().into()
    }

    #[func]
    pub fn get_online(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.online().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_percentage(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.percentage().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_power_supply(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.power_supply().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_serial(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.serial().ok().unwrap_or_default().into()
    }

    #[func]
    pub fn get_state(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.state().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_technology(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.technology().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_temperature(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.temperature().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_time_to_empty(&self) -> i64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.time_to_empty().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_time_to_full(&self) -> i64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.time_to_full().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_type(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.type_().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_update_time(&self) -> i64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.update_time().ok().unwrap_or_default() as i64
    }

    #[func]
    pub fn get_vendor(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.vendor().ok().unwrap_or_default().into()
    }

    #[func]
    pub fn get_voltage(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.voltage().ok().unwrap_or_default()
    }

    #[func]
    pub fn get_warning_level(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.warning_level().ok().unwrap_or_default()
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
            Signal::Updated => {
                self.base_mut().emit_signal("updated", &[]);
            }
        }
    }
}

/// Run the signals task
async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;
    let proxy = DeviceProxy::builder(&conn).path(path)?.build().await?;

    let signals_tx = tx.clone();
    let mut events = proxy.receive_percentage_changed().await;
    RUNTIME.spawn(async move {
        while let Some(_event) = events.next().await {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_icon_name_changed().await;
    RUNTIME.spawn(async move {
        while let Some(_event) = events.next().await {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_state_changed().await;
    RUNTIME.spawn(async move {
        while let Some(_event) = events.next().await {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_time_to_full_changed().await;
    RUNTIME.spawn(async move {
        while let Some(_event) = events.next().await {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_time_to_empty_changed().await;
    RUNTIME.spawn(async move {
        while let Some(_event) = events.next().await {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut events = proxy.receive_battery_level_changed().await;
    RUNTIME.spawn(async move {
        while let Some(_event) = events.next().await {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    Ok(())
}

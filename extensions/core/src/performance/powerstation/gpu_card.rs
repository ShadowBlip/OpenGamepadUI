use std::{
    collections::HashMap,
    sync::mpsc::{channel, Receiver, Sender, TryRecvError},
};

use futures_util::StreamExt;
use godot::{classes::ResourceLoader, prelude::*};

use crate::{
    dbus::{
        powerstation::{
            card::{CardProxy, CardProxyBlocking},
            tdp::{TDPProxy, TDPProxyBlocking},
        },
        RunError,
    },
    get_dbus_system, get_dbus_system_blocking, RUNTIME,
};

use super::{gpu_connector::GpuConnector, POWERSTATION_BUS};

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Updated,
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct GpuCard {
    base: Base<Resource>,
    dbus_path: String,
    conn: Option<zbus::blocking::Connection>,
    rx: Receiver<Signal>,
    connectors: HashMap<String, Gd<GpuConnector>>,

    #[allow(dead_code)]
    #[var(get = get_class)]
    class: GString,

    #[allow(dead_code)]
    #[var(get = get_class_id)]
    class_id: GString,

    #[allow(dead_code)]
    #[var(get = get_clock_limit_mhz_max)]
    clock_limit_mhz_max: f64,

    #[allow(dead_code)]
    #[var(get = get_clock_limit_mhz_min)]
    clock_limit_mhz_min: f64,

    #[allow(dead_code)]
    #[var(get = get_clock_value_mhz_max, set = set_clock_value_mhz_max)]
    clock_value_mhz_max: f64,

    #[allow(dead_code)]
    #[var(get = get_clock_value_mhz_min, set = set_clock_value_mhz_min)]
    clock_value_mhz_min: f64,

    #[allow(dead_code)]
    #[var(get = get_device)]
    device: GString,

    #[allow(dead_code)]
    #[var(get = get_device_id)]
    device_id: GString,

    #[allow(dead_code)]
    #[var(get = get_manual_clock, set = set_manual_clock)]
    manual_clock: bool,

    #[allow(dead_code)]
    #[var(get = get_name)]
    name: GString,

    #[allow(dead_code)]
    #[var(get = get_path)]
    path: GString,

    #[allow(dead_code)]
    #[var(get = get_revision_id)]
    revision_id: GString,

    #[allow(dead_code)]
    #[var(get = get_subdevice)]
    subdevice: GString,

    #[allow(dead_code)]
    #[var(get = get_subdevice_id)]
    subdevice_id: GString,

    #[allow(dead_code)]
    #[var(get = get_subvendor_id)]
    subvendor_id: GString,

    #[allow(dead_code)]
    #[var(get = get_vendor)]
    vendor: GString,

    #[allow(dead_code)]
    #[var(get = get_vendor_id)]
    vendor_id: GString,

    #[allow(dead_code)]
    #[var(get = get_boost, set = set_boost)]
    boost: f64,

    #[allow(dead_code)]
    #[var(get = get_power_profiles_available)]
    power_profiles_available: PackedStringArray,

    #[allow(dead_code)]
    #[var(get = get_power_profile, set = set_power_profile)]
    power_profile: GString,

    #[allow(dead_code)]
    #[var(get = get_tdp, set = set_tdp)]
    tdp: f64,

    #[allow(dead_code)]
    #[var(get = get_thermal_throttle_limit_c, set = set_thermal_throttle_limit_c)]
    thermal_throttle_limit_c: f64,
}

#[godot_api]
impl GpuCard {
    /// Create a new [EventDevice] with the given DBus path
    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();
            let (tx, rx) = channel();

            // Spawn a task to listen for GPU Card signals
            let dbus_path = path.clone().into();
            RUNTIME.spawn(async move {
                if let Err(e) = run(tx, dbus_path).await {
                    log::error!("Failed to run GPU Card task: ${e:?}");
                }
            });

            // Accept a base of type Base<Resource> and directly forward it.
            let mut instance = Self {
                base,
                conn,
                dbus_path: path.clone().into(),
                rx,
                boost: Default::default(),
                class: Default::default(),
                class_id: Default::default(),
                clock_limit_mhz_max: Default::default(),
                clock_limit_mhz_min: Default::default(),
                clock_value_mhz_max: Default::default(),
                clock_value_mhz_min: Default::default(),
                connectors: HashMap::new(),
                device: Default::default(),
                device_id: Default::default(),
                manual_clock: Default::default(),
                name: Default::default(),
                path: Default::default(),
                power_profile: Default::default(),
                power_profiles_available: Default::default(),
                revision_id: Default::default(),
                subdevice: Default::default(),
                subdevice_id: Default::default(),
                subvendor_id: Default::default(),
                tdp: Default::default(),
                thermal_throttle_limit_c: Default::default(),
                vendor: Default::default(),
                vendor_id: Default::default(),
            };

            // Discover any connectors
            let mut connectors = HashMap::new();
            if let Some(card) = instance.get_proxy() {
                if let Ok(connector_paths) = card.enumerate_connectors() {
                    for conn_path in connector_paths {
                        let connector = GpuConnector::new(conn_path.as_str());
                        connectors.insert(conn_path.to_string(), connector);
                    }
                }
            }
            instance.connectors = connectors;

            instance
        })
    }

    /// Return a proxy instance to the GPU card interface
    fn get_proxy(&self) -> Option<CardProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            CardProxyBlocking::builder(conn)
                .path(self.dbus_path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Return a proxy instance to the TDP interface
    fn get_tdp_proxy(&self) -> Option<TDPProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            TDPProxyBlocking::builder(conn)
                .path(self.dbus_path.clone())
                .ok()
                .and_then(|builder| builder.build().ok())
        } else {
            None
        }
    }

    /// Get or create a [DBusDevice] with the given DBus path. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(path: &str) -> Gd<Self> {
        let res_path = format!("dbus://{POWERSTATION_BUS}{path}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::trace!("Resource already exists, loading that instead");
                let device: Gd<GpuCard> = res.cast();
                device
            } else {
                let mut device = GpuCard::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = GpuCard::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the GPU connector instance
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.dbus_path.clone().into()
    }

    /// Returns true if the card supports tdp
    #[func]
    pub fn supports_tdp(&self) -> bool {
        let tdp = self.get_tdp();
        tdp > 1.0
    }

    /// Returns the connectors associated with this GPU card
    #[func]
    pub fn get_connectors(&self) -> Array<Gd<GpuConnector>> {
        let mut connectors = array![];
        let Some(proxy) = self.get_proxy() else {
            return connectors;
        };
        let paths = proxy.enumerate_connectors().unwrap_or_default();
        for path in paths {
            let connector = GpuConnector::new(path.as_str());
            connectors.push(&connector);
        }

        connectors
    }

    #[func]
    pub fn get_name(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.name().unwrap_or_default().into()
    }

    #[func]
    pub fn get_path(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.path().unwrap_or_default().into()
    }

    #[func]
    pub fn get_thermal_throttle_limit_c(&self) -> f64 {
        let Some(proxy) = self.get_tdp_proxy() else {
            return Default::default();
        };
        proxy.thermal_throttle_limit_c().unwrap_or_default()
    }

    #[func]
    pub fn set_thermal_throttle_limit_c(&self, value: f64) {
        let Some(proxy) = self.get_tdp_proxy() else {
            return Default::default();
        };
        proxy
            .set_thermal_throttle_limit_c(value)
            .unwrap_or_default()
    }

    #[func]
    pub fn get_power_profiles_available(&self) -> PackedStringArray {
        let Some(proxy) = self.get_tdp_proxy() else {
            return Default::default();
        };
        let available = proxy.power_profiles_available().unwrap_or_default();
        let mut result = PackedStringArray::new();
        for profile in available.iter() {
            let godot_profile = profile.to_godot();
            result.push(&godot_profile);
        }
        result
    }

    #[func]
    pub fn get_power_profile(&self) -> GString {
        let Some(proxy) = self.get_tdp_proxy() else {
            return Default::default();
        };
        proxy.power_profile().unwrap_or_default().into()
    }

    #[func]
    pub fn set_power_profile(&self, value: GString) {
        let Some(proxy) = self.get_tdp_proxy() else {
            return Default::default();
        };
        let value = value.to_string();
        proxy.set_power_profile(value.as_str()).unwrap_or_default()
    }

    #[func]
    pub fn get_boost(&self) -> f64 {
        let Some(proxy) = self.get_tdp_proxy() else {
            return Default::default();
        };
        proxy.boost().unwrap_or_default()
    }

    #[func]
    pub fn set_boost(&self, value: f64) {
        let Some(proxy) = self.get_tdp_proxy() else {
            return Default::default();
        };
        proxy.set_boost(value).unwrap_or_default()
    }

    #[func]
    pub fn get_manual_clock(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.manual_clock().unwrap_or_default()
    }

    #[func]
    pub fn set_manual_clock(&self, value: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_manual_clock(value).unwrap_or_default()
    }

    #[func]
    pub fn get_clock_value_mhz_min(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.clock_value_mhz_min().unwrap_or_default()
    }

    #[func]
    pub fn set_clock_value_mhz_min(&self, value: f64) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_clock_value_mhz_min(value).unwrap_or_default()
    }

    #[func]
    pub fn get_clock_value_mhz_max(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.clock_value_mhz_max().unwrap_or_default()
    }

    #[func]
    pub fn set_clock_value_mhz_max(&self, value: f64) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_clock_value_mhz_max(value).unwrap_or_default()
    }

    #[func]
    pub fn get_device_id(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.device_id().unwrap_or_default().into()
    }

    #[func]
    pub fn get_subdevice_id(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.subdevice_id().unwrap_or_default().into()
    }

    #[func]
    pub fn get_subvendor_id(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.subvendor_id().unwrap_or_default().into()
    }

    #[func]
    pub fn get_vendor(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.vendor().unwrap_or_default().into()
    }

    #[func]
    pub fn get_vendor_id(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.vendor_id().unwrap_or_default().into()
    }

    #[func]
    pub fn get_tdp(&self) -> f64 {
        let Some(proxy) = self.get_tdp_proxy() else {
            return Default::default();
        };
        proxy.tdp().unwrap_or_default()
    }

    #[func]
    pub fn set_tdp(&self, value: f64) {
        let Some(proxy) = self.get_tdp_proxy() else {
            return Default::default();
        };
        proxy.set_tdp(value).unwrap_or_default()
    }

    #[func]
    pub fn get_subdevice(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.subdevice().unwrap_or_default().into()
    }

    #[func]
    pub fn get_revision_id(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.revision_id().unwrap_or_default().into()
    }

    #[func]
    pub fn get_device(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.device().unwrap_or_default().into()
    }

    #[func]
    pub fn get_clock_limit_mhz_min(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.clock_limit_mhz_min().unwrap_or_default()
    }

    #[func]
    pub fn get_clock_limit_mhz_max(&self) -> f64 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.clock_limit_mhz_max().unwrap_or_default()
    }

    #[func]
    pub fn get_class_id(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.class_id().unwrap_or_default().into()
    }

    #[func]
    pub fn get_class(&self) -> GString {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.class().unwrap_or_default().into()
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

        // Process child connector signals
        for connector in self.connectors.values_mut() {
            connector.bind_mut().process();
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        log::trace!("Got signal: {signal:?}");
        match signal {
            Signal::Updated => {
                self.base_mut().emit_signal("updated", &[]);
            }
        }
    }
}

/// Runs GPU connector tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;
    let proxy = CardProxy::builder(&conn)
        .path(path.clone())?
        .build()
        .await?;

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_clock_value_mhz_min_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_clock_value_mhz_max_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_manual_clock_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let tdp_proxy = TDPProxy::builder(&conn).path(path)?.build().await?;

    let signals_tx = tx.clone();
    let mut property_changed = tdp_proxy.receive_tdp_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = tdp_proxy.receive_boost_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = tdp_proxy.receive_power_profile_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = tdp_proxy.receive_thermal_throttle_limit_c_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    Ok(())
}

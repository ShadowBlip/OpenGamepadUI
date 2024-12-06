use std::{
    collections::HashMap,
    sync::mpsc::{channel, Receiver, Sender, TryRecvError},
};

use futures_util::StreamExt;
use godot::{classes::ResourceLoader, prelude::*};

use crate::{
    dbus::{
        powerstation::cpu::{CPUProxy, CPUProxyBlocking},
        RunError,
    },
    get_dbus_system, get_dbus_system_blocking, RUNTIME,
};

use super::{cpu_core::CpuCore, POWERSTATION_BUS};

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Updated,
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct Cpu {
    base: Base<Resource>,
    path: String,
    conn: Option<zbus::blocking::Connection>,
    rx: Receiver<Signal>,
    cores: HashMap<String, Gd<CpuCore>>,

    #[allow(dead_code)]
    #[var(get = get_boost_enabled, set = set_boost_enabled)]
    boost_enabled: bool,
    #[allow(dead_code)]
    #[var(get = get_cores_count)]
    cores_count: u32,
    #[allow(dead_code)]
    #[var(get = get_cores_enabled, set = set_cores_enabled)]
    cores_enabled: u32,
    #[allow(dead_code)]
    #[var(get = get_features)]
    features: PackedStringArray,
    #[allow(dead_code)]
    #[var(get = get_smt_enabled, set = set_smt_enabled)]
    smt_enabled: bool,
}

#[godot_api]
impl Cpu {
    /// Create a new [Cpu] instance with the given DBus path
    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();
            let (tx, rx) = channel();

            // Spawn a task to listen for CPU signals
            let dbus_path = path.clone().into();
            RUNTIME.spawn(async move {
                if let Err(e) = run(tx, dbus_path).await {
                    log::error!("Failed to run CPU task: ${e:?}");
                }
            });

            // Accept a base of type Base<Resource> and directly forward it.
            let mut instance = Self {
                base,
                conn,
                path: path.clone().into(),
                cores: HashMap::new(),
                rx,
                boost_enabled: Default::default(),
                cores_count: Default::default(),
                cores_enabled: Default::default(),
                features: Default::default(),
                smt_enabled: Default::default(),
            };

            // Discover any CPU cores
            let mut cores = HashMap::new();
            if let Some(cpu) = instance.get_proxy() {
                if let Ok(core_paths) = cpu.enumerate_cores() {
                    for core_path in core_paths {
                        let core = CpuCore::new(core_path.as_str());
                        cores.insert(core_path.to_string(), core);
                    }
                }
            }
            instance.cores = cores;

            instance
        })
    }

    /// Return a proxy instance to the composite device
    fn get_proxy(&self) -> Option<CPUProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            CPUProxyBlocking::builder(conn)
                .path(self.path.clone())
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
                let device: Gd<Cpu> = res.cast();
                device
            } else {
                let mut device = Cpu::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = Cpu::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the CPU instance
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.clone().into()
    }

    /// Return all the CPU cores for the CPU
    #[func]
    pub fn get_cores(&self) -> Array<Gd<CpuCore>> {
        let mut cores = array![];
        for core in self.cores.values() {
            cores.push(core);
        }

        cores
    }

    /// Returns whether or not the CPU has the given feature flag
    #[func]
    pub fn has_feature(&self, flag: GString) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy
            .has_feature(flag.to_string().as_str())
            .unwrap_or(false)
    }

    /// Returns whether or not boost is enabled
    #[func]
    pub fn get_boost_enabled(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.boost_enabled().unwrap_or_default()
    }

    /// Sets boost to the given value
    #[func]
    pub fn set_boost_enabled(&self, enabled: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_boost_enabled(enabled).ok();
    }

    /// Returns the total number of detected CPU cores
    #[func]
    pub fn get_cores_count(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.cores_count().unwrap_or_default()
    }

    /// Returns the number of enabled CPU cores
    #[func]
    pub fn get_cores_enabled(&self) -> u32 {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.cores_enabled().unwrap_or_default()
    }

    /// Set the number of enabled CPU cores. Cannot be less than 1.
    #[func]
    pub fn set_cores_enabled(&self, enabled_count: u32) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_cores_enabled(enabled_count).unwrap_or_default()
    }

    /// Returns a list of supported CPU feature flags
    #[func]
    pub fn get_features(&self) -> PackedStringArray {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        let features = proxy.features().unwrap_or_default();
        let features: Vec<GString> = features.into_iter().map(|f| f.to_godot()).collect();
        features.into()
    }

    /// Returns whether or not SMT is enabled
    #[func]
    pub fn get_smt_enabled(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.smt_enabled().unwrap_or_default()
    }

    /// Set SMT to the given value
    #[func]
    pub fn set_smt_enabled(&self, enabled: bool) {
        let Some(proxy) = self.get_proxy() else {
            return Default::default();
        };
        proxy.set_smt_enabled(enabled).ok();
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

        // Process signals for any child cores
        for (_, core) in self.cores.iter_mut() {
            core.bind_mut().process();
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

/// Runs CPU tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>, path: String) -> Result<(), RunError> {
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;
    let proxy = CPUProxy::builder(&conn).path(path)?.build().await?;

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_features_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_cores_count_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_smt_enabled_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_boost_enabled_changed().await;
    RUNTIME.spawn(async move {
        while (property_changed.next().await).is_some() {
            let signal = Signal::Updated;
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    let signals_tx = tx.clone();
    let mut property_changed = proxy.receive_cores_enabled_changed().await;
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

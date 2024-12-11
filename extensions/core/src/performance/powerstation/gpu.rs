use std::collections::HashMap;

use godot::{classes::ResourceLoader, prelude::*};

use crate::{dbus::powerstation::gpu::GPUProxyBlocking, get_dbus_system_blocking};

use super::{gpu_card::GpuCard, POWERSTATION_BUS};

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct Gpu {
    base: Base<Resource>,
    path: String,
    conn: Option<zbus::blocking::Connection>,
    cards: HashMap<String, Gd<GpuCard>>,
}

#[godot_api]
impl Gpu {
    /// Create a new [Cpu] instance with the given DBus path
    fn from_path(path: GString) -> Gd<Self> {
        Gd::from_init_fn(|base| {
            // Create a connection to DBus
            let conn = get_dbus_system_blocking().ok();

            // Accept a base of type Base<Resource> and directly forward it.
            let mut instance = Self {
                base,
                conn,
                path: path.clone().into(),
                cards: HashMap::new(),
            };

            // Discover any GPU cards
            let mut cards = HashMap::new();
            if let Some(gpu) = instance.get_proxy() {
                if let Ok(card_paths) = gpu.enumerate_cards() {
                    for card_path in card_paths {
                        let core = GpuCard::new(card_path.as_str());
                        cards.insert(card_path.to_string(), core);
                    }
                }
            }
            instance.cards = cards;

            instance
        })
    }

    /// Return a proxy instance to the composite device
    fn get_proxy(&self) -> Option<GPUProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            GPUProxyBlocking::builder(conn)
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
                let device: Gd<Gpu> = res.cast();
                device
            } else {
                let mut device = Gpu::from_path(path.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = Gpu::from_path(path.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Return the DBus path to the CPU instance
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.clone().into()
    }

    #[func]
    pub fn get_cards(&self) -> Array<Gd<GpuCard>> {
        let mut cards = array![];
        for core in self.cards.values() {
            cards.push(core);
        }

        cards
    }

    /// Dispatches signals
    pub fn process(&mut self) {
        // Process signals for any child cores
        for (_, card) in self.cards.iter_mut() {
            card.bind_mut().process();
        }
    }
}

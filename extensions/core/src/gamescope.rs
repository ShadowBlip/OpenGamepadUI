pub mod x11_client;

use std::collections::HashMap;
use std::env;
use x11_client::GamescopeXWayland;

use godot::prelude::*;

use godot::classes::{Engine, Resource};

#[derive(GodotClass)]
#[class(base=Resource)]
pub struct GamescopeInstance {
    base: Base<Resource>,
    xwaylands: HashMap<String, Gd<GamescopeXWayland>>,
    xwayland_primary: String,
    xwayland_ogui: String,
    xwayland_game: String,
}

#[godot_api]
impl GamescopeInstance {
    /// Primary Gamescope xwayland instance
    #[constant]
    const XWAYLAND_TYPE_PRIMARY: u32 = 0;

    /// Xwayland instance that OpenGamepadUI is running on
    #[constant]
    const XWAYLAND_TYPE_OGUI: u32 = 1;

    /// Xwayland instance where games run
    #[constant]
    const XWAYLAND_TYPE_GAME: u32 = 2;

    /// Gamescope is hard-coded to look for STEAM_GAME=769 to determine if it is the
    /// overlay app.
    #[constant]
    const OVERLAY_GAME_ID: u32 = 769;

    /// Return the Gamescope XWayland of the given type.
    #[func]
    pub fn get_xwayland(&self, kind: u32) -> Option<Gd<GamescopeXWayland>> {
        match kind {
            GamescopeInstance::XWAYLAND_TYPE_PRIMARY => {
                let xwayland = self.xwaylands.get(&self.xwayland_primary);
                xwayland.cloned()
            }
            GamescopeInstance::XWAYLAND_TYPE_OGUI => {
                let xwayland = self.xwaylands.get(&self.xwayland_ogui);
                xwayland.cloned()
            }
            GamescopeInstance::XWAYLAND_TYPE_GAME => {
                let xwayland = self.xwaylands.get(&self.xwayland_game);
                xwayland.cloned()
            }
            _ => None,
        }
    }

    /// Return all known XWayland instances
    #[func]
    pub fn get_xwaylands(&self) -> Array<Gd<GamescopeXWayland>> {
        let mut xwaylands = array![];
        for xwayland in self.xwaylands.values() {
            xwaylands.push(xwayland);
        }

        xwaylands
    }

    /// Returns the XWayland display with the given name (e.g. ":0")
    #[func]
    pub fn get_xwayland_by_name(&self, name: GString) -> Option<Gd<GamescopeXWayland>> {
        let name: String = name.into();
        self.xwaylands.get(&name).cloned()
    }

    /// Process Gamescope signals and emit them as Godot signals. This method
    /// should be called every frame in the "_process" loop of a node.
    #[func]
    pub fn process(&mut self) {
        for (_, xwayland) in self.xwaylands.iter_mut() {
            xwayland.bind_mut().process();
        }
    }
}

#[godot_api]
impl IResource for GamescopeInstance {
    /// Called upon object initialization in the engine
    fn init(base: Base<Self::Base>) -> Self {
        log::debug!("Initializing Gamescope instance");

        // Don't run in the editor
        let engine = Engine::singleton();
        if engine.is_editor_hint() {
            return Self {
                base,
                xwaylands: Default::default(),
                xwayland_primary: Default::default(),
                xwayland_ogui: Default::default(),
                xwayland_game: Default::default(),
            };
        }

        // Discover any gamescope instances
        let result = gamescope_x11_client::discover_gamescope_displays();
        let x11_displays = match result {
            Ok(displays) => displays,
            Err(e) => {
                log::warn!("Failed to get Gamescope displays: {e:?}");
                return Self {
                    base,
                    xwaylands: HashMap::new(),
                    xwayland_primary: Default::default(),
                    xwayland_ogui: Default::default(),
                    xwayland_game: Default::default(),
                };
            }
        };

        // Get the X11 display that the process knows about
        let ogui_display = env::var("DISPLAY").unwrap_or(":0".into());

        // Keep track of discovered XWaylands
        let mut xwaylands = HashMap::new();
        let mut xwayland_primary = Default::default();
        let mut xwayland_ogui = Default::default();
        let mut xwayland_game = Default::default();

        // Create an XWayland instance for each discovered XWayland display
        for display in x11_displays {
            log::debug!("Discovered XWayland display: {display}");
            let xwayland = GamescopeXWayland::new(display.as_str());

            // Categorize the discovered displays
            if display == ogui_display {
                xwayland_ogui = display.clone();
            }
            if xwayland.bind().get_is_primary() {
                xwayland_primary = display.clone();
            } else {
                xwayland_game = display.clone();
            }

            xwaylands.insert(display, xwayland);
        }

        // Create a new Gamescope instance
        Self {
            base,
            xwaylands,
            xwayland_ogui,
            xwayland_game,
            xwayland_primary,
        }
    }
}

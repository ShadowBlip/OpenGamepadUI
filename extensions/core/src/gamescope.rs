pub mod x11_client;

use std::collections::{HashMap, HashSet};
use std::env;
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, Instant};
use x11_client::GamescopeXWayland;

use gamescope_x11_client::atoms::GamescopeAtom;
use gamescope_x11_client::xwayland::XWayland;

use godot::prelude::*;

use godot::classes::{Engine, Resource};

/// How long to wait for an X11 display to connect
/// before giving up on it.
const DISPLAY_PROBE_TIMEOUT: Duration = Duration::from_secs(2);

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

    /// Steam sets this unknown value as a baselayer app id
    #[constant]
    const EXTRA_UNKNOWN_GAME_ID: u32 = 413091;

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
        let result = discover_gamescope_displays();
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

/// Returns the names of every X11 display that is a Gamescope XWayland
fn discover_gamescope_displays() -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let mut seen = HashSet::new();
    let displays = gamescope_x11_client::discover_x11_displays()?
        .into_iter()
        .filter(|display| seen.insert(display.clone()));

    let probes: Vec<(String, mpsc::Receiver<bool>)> = displays
        .map(|display| {
            let (tx, rx) = mpsc::sync_channel(1);
            let name = display.clone();
            thread::spawn(move || {
                let _ = tx.try_send(is_gamescope_display(&name));
            });
            (display, rx)
        })
        .collect();

    let deadline = Instant::now() + DISPLAY_PROBE_TIMEOUT;
    let mut gamescope_displays = Vec::new();
    for (display, rx) in probes {
        let remaining = deadline.saturating_duration_since(Instant::now());
        match rx.recv_timeout(remaining) {
            Ok(true) => gamescope_displays.push(display),
            Ok(false) => (),
            Err(_) => log::warn!("Display {display} did not respond in time; skipping it"),
        }
    }

    Ok(gamescope_displays)
}

/// Connects to the given display and reports whether it is a Gamescope XWayland.
fn is_gamescope_display(display: &str) -> bool {
    let mut xwayland = XWayland::new(display.to_string());
    if let Err(e) = xwayland.connect() {
        log::debug!("Failed to connect to display {display}: {e:?}");
        return false;
    }

    let root_window_id = match xwayland.get_root_window_id() {
        Ok(root_window_id) => root_window_id,
        Err(e) => {
            log::debug!("Failed to get root window for display {display}: {e:?}");
            return false;
        }
    };

    match xwayland.has_xprop(root_window_id, GamescopeAtom::XwaylandServerId) {
        Ok(is_gamescope) => is_gamescope,
        Err(e) => {
            log::debug!("Failed to query display {display}: {e:?}");
            false
        }
    }
}

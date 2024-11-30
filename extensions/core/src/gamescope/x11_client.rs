use gamescope_x11_client::{
    atoms::GamescopeAtom,
    xwayland::{BlurMode, Primary, WindowLifecycleEvent, XWayland},
};
use std::{
    collections::HashMap,
    sync::mpsc::{channel, Receiver, Sender, TryRecvError},
    time::Duration,
};
use tokio::task::AbortHandle;

use godot::{obj::WithBaseField, prelude::*};

use godot::classes::{Resource, ResourceLoader};

use crate::RUNTIME;

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    WindowCreated { window_id: u32 },
    WindowDestroyed { window_id: u32 },
    WindowPropertyChanged { window_id: u32, property: String },
    PropertyChanged { property: String },
}

#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct GamescopeXWayland {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    tx: Sender<Signal>,
    xwayland: XWayland,
    window_watch_handles: HashMap<u32, AbortHandle>,

    /// The name of the XWayland instance (e.g. ":0")
    #[var]
    name: GString,
    /// Returns true if this [GamescopeXWayland] is the primary instance
    #[var]
    is_primary: bool,
    /// Returns the root window id of the [GamescopeXWayland] instance
    #[var]
    root_window_id: u32,
    /// List of windows currently being watched for property changes
    #[var(get = get_watched_windows)]
    watched_windows: PackedInt64Array,
    /// List of focusable apps
    #[var(get = get_focusable_apps)]
    focusable_apps: PackedInt64Array,
    /// List of focusable windows
    #[var(get = get_focusable_windows)]
    focusable_windows: PackedInt64Array,
    /// List of focusable window names
    #[var(get = get_focusable_window_names)]
    focusable_window_names: PackedStringArray,
    /// Currently focused window id
    #[var(get = get_focused_window)]
    focused_window: u32,
    /// Currently focused app id
    #[var(get = get_focused_app)]
    focused_app: u32,
    /// Currently focused gfx app id
    #[var(get = get_focused_app_gfx)]
    focused_app_gfx: u32,
    /// Whether or not the overlay window is currently focused
    #[var(get = get_overlay_focused)]
    overlay_focused: bool,
    /// Current Gamescope FPS limit
    #[var(get = get_fps_limit, set = set_fps_limit)]
    fps_limit: u32,
    /// Gamecope blur mode (0 - off, 1 - cond, 2 - always)
    #[var(get = get_blur_mode, set = set_blur_mode)]
    blur_mode: u32,
    /// Gamescope blur radius
    #[var(get = get_blur_radius, set = set_blur_radius)]
    blur_radius: u32,
    /// Whether or not Gamescope should be allowed to screen tear
    #[var(get = get_allow_tearing, set = set_allow_tearing)]
    allow_tearing: bool,
    /// Current manually focused window
    #[var(get = get_baselayer_window, set = set_baselayer_window)]
    baselayer_window: u32,
    /// Current manually focused app
    #[var(get = get_baselayer_app, set = set_baselayer_app)]
    baselayer_app: u32,
}

#[godot_api]
impl GamescopeXWayland {
    #[constant]
    const BLUR_MODE_OFF: u32 = 0;
    #[constant]
    const BLUR_MODE_COND: u32 = 1;
    #[constant]
    const BLUR_MODE_ALWAYS: u32 = 2;

    #[signal]
    fn window_created(window_id: u32);

    #[signal]
    fn window_destroyed(window_id: u32);

    #[signal]
    fn window_property_updated(window_id: u32, property: GString);

    #[signal]
    fn focused_app_updated(from: u32, to: u32);

    #[signal]
    fn focused_app_gfx_updated(from: u32, to: u32);

    #[signal]
    fn focusable_apps_updated(from: PackedInt64Array, to: PackedInt64Array);

    #[signal]
    fn focused_window_updated(from: u32, to: u32);

    #[signal]
    fn focusable_windows_updated(from: PackedInt64Array, to: PackedInt64Array);

    #[signal]
    fn baselayer_window_updated(from: u32, to: u32);

    #[signal]
    fn baselayer_app_updated(from: u32, to: u32);

    /// Create a new [GamescopeXWayland] with the given name (e.g. ":0")
    pub fn from_name(name: GString) -> Gd<Self> {
        // Create a channel to communicate with the signals task
        log::debug!("Gamescope XWayland created with name: {name}");
        let (tx, rx) = channel();

        // Create an XWayland client instance for this display
        let mut xwayland = XWayland::new(name.clone().into());
        if let Err(e) = xwayland.connect() {
            log::error!("Failed to connect to XWayland display '{name}': {e:?}");
        }
        let is_primary = xwayland.is_primary_instance().unwrap_or_default();
        let root_window_id = xwayland.get_root_window_id().unwrap_or_default();

        // If this XWayland instance is a primary instance, listen for signals
        if is_primary {
            // Spawn a task to listen for property changes
            if let Ok((_, property_rx)) = xwayland.listen_for_property_changes() {
                let signals_tx = tx.clone();
                RUNTIME.spawn_blocking(move || {
                    for event in property_rx.into_iter() {
                        let signal = Signal::PropertyChanged { property: event };
                        if let Err(e) = signals_tx.send(signal) {
                            log::error!("Error sending property changed signal: {e:?}");
                            break;
                        }
                    }
                });
            } else {
                log::error!("Failed to listen for XWayland property changes");
            }
        }

        // Spawn a task to listen for window creation events
        if let Ok((_, windows_rx)) = xwayland.listen_for_window_lifecycle() {
            let signals_tx = tx.clone();
            RUNTIME.spawn_blocking(move || {
                for (event, window_id) in windows_rx.into_iter() {
                    let signal = match event {
                        WindowLifecycleEvent::Created => Signal::WindowCreated { window_id },
                        WindowLifecycleEvent::Destroyed => Signal::WindowDestroyed { window_id },
                    };
                    if let Err(e) = signals_tx.send(signal) {
                        log::error!("Error sending window signal: {e:?}");
                        break;
                    }
                }
            });
        } else {
            log::error!("Failed to listen for XWayland windows created/destroyed");
        }

        // Setup the initial state
        Gd::from_init_fn(|base| {
            // Accept a base of type Base<Resource> and directly forward it.
            Self {
                base,
                rx,
                tx,
                name,
                xwayland,
                is_primary,
                root_window_id,
                watched_windows: Default::default(),
                window_watch_handles: Default::default(),
                focusable_apps: Default::default(),
                focusable_windows: Default::default(),
                focusable_window_names: Default::default(),
                focused_window: Default::default(),
                focused_app: Default::default(),
                focused_app_gfx: Default::default(),
                overlay_focused: Default::default(),
                fps_limit: Default::default(),
                blur_mode: Default::default(),
                blur_radius: Default::default(),
                allow_tearing: Default::default(),
                baselayer_window: Default::default(),
                baselayer_app: Default::default(),
            }
        })
    }

    /// Get or create a [GamescopeXWayland] with the given name. If an instance
    /// already exists with the given path, then it will be loaded from the resource
    /// cache.
    pub fn new(name: &str) -> Gd<Self> {
        let res_path = format!("gamescope://xwayland/{name}");

        // Check to see if a resource already exists for this device
        let mut resource_loader = ResourceLoader::singleton();
        if resource_loader.exists(res_path.as_str()) {
            if let Some(res) = resource_loader.load(res_path.as_str()) {
                log::debug!("Resource already exists with path '{res_path}', loading that instead");
                let device: Gd<GamescopeXWayland> = res.cast();
                device
            } else {
                let mut device = GamescopeXWayland::from_name(name.to_string().into());
                device.take_over_path(res_path.as_str());
                device
            }
        } else {
            let mut device = GamescopeXWayland::from_name(name.to_string().into());
            device.take_over_path(res_path.as_str());
            device
        }
    }

    /// Returns the list of currently watched windows.
    #[func]
    pub fn get_watched_windows(&self) -> PackedInt64Array {
        self.watched_windows.clone()
    }

    /// Start watching the given window. The [WindowPropertyChanged] signal
    /// will fire whenever a window property changes on the window. Use
    /// [unwatch_window] to stop watching the given window.
    #[func]
    pub fn watch_window(&mut self, window_id: u32) -> i32 {
        if self.watched_windows.contains(window_id as i64) {
            log::warn!("Window {window_id} is already being watched");
            return 0;
        }
        self.watched_windows.push(window_id as i64);

        // Spawn a new thread to listen for window property changes
        let (_, rx) = match self.xwayland.listen_for_window_property_changes(window_id) {
            Ok(result) => result,
            Err(e) => {
                log::error!("Failed to watch window properties for window '{window_id}': {e:?}");
                return -1;
            }
        };

        // Spawn a task to listen for window changes and emit signals
        let signals_tx = self.tx.clone();
        let task = RUNTIME.spawn(async move {
            log::debug!("Started listening for property changes on window: {window_id}");
            // NOTE: only async tasks support abort, so we need to resort to polling here
            'outer: loop {
                // Consume all messages from the channel and emit signals
                'inner: loop {
                    let event = match rx.try_recv() {
                        Ok(value) => value,
                        Err(e) => match e {
                            TryRecvError::Empty => break 'inner,
                            TryRecvError::Disconnected => {
                                log::error!("Backend thread is not running!");
                                return;
                            }
                        },
                    };
                    let signal = Signal::WindowPropertyChanged {
                        window_id,
                        property: event,
                    };
                    if let Err(e) = signals_tx.send(signal) {
                        log::error!("Failed to send property change signal: {e:?}");
                        break 'outer;
                    }
                }

                tokio::time::sleep(Duration::from_millis(40)).await;
            }

            log::debug!("Stopped listening for property changes on window: {window_id}");
        });

        // Keep a list of abort handles so the watch task can be cancelled.
        self.window_watch_handles
            .insert(window_id, task.abort_handle());

        0
    }

    /// Stop watching the given window. The [WindowPropertyChanged] signal will
    /// no longer fire for the given window.
    #[func]
    pub fn unwatch_window(&mut self, window_id: u32) -> i32 {
        let window_id = window_id as i64;
        if !self.watched_windows.contains(window_id) {
            return 0;
        }
        if let Some(idx) = self.watched_windows.find(window_id, None) {
            self.watched_windows.remove(idx);
        }

        // Cancel the listener task
        let Some(task) = self.window_watch_handles.get(&(window_id as u32)) else {
            log::error!("Task wasn't found but was being watched: {window_id}");
            return -1;
        };

        task.abort();

        0
    }

    /// Discover the process IDs that are associated with the given window
    #[func]
    pub fn get_pids_for_window(&self, window_id: u32) -> PackedInt64Array {
        let pids = match self.xwayland.get_pids_for_window(window_id) {
            Ok(pids) => pids,
            Err(e) => {
                log::error!("Failed to get pids for window '{window_id}': {e:?}");
                return PackedInt64Array::new();
            }
        };
        let pids: Vec<i64> = pids.into_iter().map(|pid| pid as i64).collect();

        pids.into()
    }

    /// Returns the window id(s) for the given process ID.
    #[func]
    pub fn get_windows_for_pid(&self, pid: u32) -> PackedInt64Array {
        let windows = match self.xwayland.get_windows_for_pid(pid) {
            Ok(windows) => windows,
            Err(e) => {
                log::error!("Failed to get windows for pid '{pid}': {e:?}");
                return PackedInt64Array::new();
            }
        };
        let windows: Vec<i64> = windows.into_iter().map(|id| id as i64).collect();

        windows.into()
    }

    /// Returns the window name of the given window
    #[func]
    fn get_window_name(&self, window_id: u32) -> GString {
        let name = match self.xwayland.get_window_name(window_id) {
            Ok(name) => name,
            Err(e) => {
                log::error!("Failed to get window name for window '{window_id}': {e:?}");
                return "".into();
            }
        };

        name.unwrap_or_default().into()
    }

    /// Returns the window ids of the children of the given window
    #[func]
    fn get_window_children(&self, window_id: u32) -> PackedInt64Array {
        let windows = match self.xwayland.get_window_children(window_id) {
            Ok(windows) => windows,
            Err(e) => {
                log::error!("Failed to get window children for window '{window_id}': {e:?}");
                return PackedInt64Array::new();
            }
        };
        let windows: Vec<i64> = windows.into_iter().map(|id| id as i64).collect();

        windows.into()
    }

    /// Recursively returns all child windows of the given window id
    #[func]
    fn get_all_windows(&self, window_id: u32) -> PackedInt64Array {
        let windows = match self.xwayland.get_all_windows(window_id) {
            Ok(windows) => windows,
            Err(e) => {
                log::error!("Failed to get all window children for window '{window_id}': {e:?}");
                return PackedInt64Array::new();
            }
        };
        let windows: Vec<i64> = windows.into_iter().map(|id| id as i64).collect();

        windows.into()
    }

    /// Returns the currently set app ID on the given window. Returns zero if no
    /// app id was found.
    #[func]
    fn get_app_id(&self, window_id: u32) -> u32 {
        match self.xwayland.get_app_id(window_id) {
            Ok(app_id) => app_id.unwrap_or_default(),
            Err(e) => {
                log::error!("Failed to get app id for window '{window_id}': {e:?}");
                0
            }
        }
    }

    /// Sets the app ID on the given window. Returns zero if operation succeeds.
    #[func]
    fn set_app_id(&self, window_id: u32, app_id: u32) -> i32 {
        if let Err(e) = self.xwayland.set_app_id(window_id, app_id) {
            log::error!("Failed to set app id {app_id} on window '{window_id}': {e:?}");
            return -1;
        }
        0
    }

    /// Removes the app ID on the given window. Returns zero if operation succeeds.
    #[func]
    fn remove_app_id(&self, window_id: u32) -> i32 {
        if let Err(e) = self
            .xwayland
            .remove_xprop(window_id, GamescopeAtom::SteamGame)
        {
            log::error!("Failed to remove app id from window '{window_id}': {e:?}");
            return -1;
        }
        0
    }

    /// Returns whether or not the given window has an app ID set
    #[func]
    fn has_app_id(&self, window_id: u32) -> bool {
        match self.xwayland.has_app_id(window_id) {
            Ok(v) => v,
            Err(e) => {
                log::error!("Failed to check window '{window_id}' for app id: {e:?}");
                false
            }
        }
    }

    /// Returns whether or not the given window has the STEAM_NOTIFICATION property
    #[func]
    fn has_notification(&self, window_id: u32) -> bool {
        match self
            .xwayland
            .has_xprop(window_id, GamescopeAtom::SteamNotification)
        {
            Ok(v) => v,
            Err(e) => {
                log::error!(
                    "Failed to check window '{window_id}' has STEAM_NOTIFICATION property: {e:?}"
                );
                false
            }
        }
    }

    /// Returns whether or not the given window has the STEAM_INPUT_FOCUS property
    #[func]
    fn has_input_focus(&self, window_id: u32) -> bool {
        match self
            .xwayland
            .has_xprop(window_id, GamescopeAtom::SteamInputFocus)
        {
            Ok(v) => v,
            Err(e) => {
                log::error!(
                    "Failed to check window '{window_id}' has STEAM_INPUT_FOCUS property: {e:?}"
                );
                false
            }
        }
    }

    /// Returns whether or not the given window has the STEAM_OVERLAY property
    #[func]
    fn has_overlay(&self, window_id: u32) -> bool {
        match self
            .xwayland
            .has_xprop(window_id, GamescopeAtom::SteamOverlay)
        {
            Ok(v) => v,
            Err(e) => {
                log::error!(
                    "Failed to check window '{window_id}' has STEAM_OVERLAY property: {e:?}"
                );
                false
            }
        }
    }

    /// --- XWayland Primary ---

    /// Return a list of focusable apps
    #[func]
    fn get_focusable_apps(&mut self) -> PackedInt64Array {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_focusable_apps() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get focusable apps: {e:?}");
                return Default::default();
            }
        };
        let Some(focusable) = value else {
            return Default::default();
        };
        let focusable: Vec<i64> = focusable.into_iter().map(|v| v as i64).collect();
        self.focusable_apps = focusable.into();
        self.focusable_apps.clone()
    }

    /// Return a list of focusable windows
    #[func]
    fn get_focusable_windows(&mut self) -> PackedInt64Array {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_focusable_windows() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get focusable windows: {e:?}");
                return Default::default();
            }
        };
        let Some(focusable) = value else {
            return Default::default();
        };
        let focusable: Vec<i64> = focusable.into_iter().map(|v| v as i64).collect();
        self.focusable_windows = focusable.into();
        self.focusable_windows.clone()
    }

    /// Returns a list of focusable window names
    #[func]
    fn get_focusable_window_names(&mut self) -> PackedStringArray {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_focusable_window_names() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get focusable windows: {e:?}");
                return Default::default();
            }
        };
        let value: Vec<GString> = value.into_iter().map(GString::from).collect();
        self.focusable_window_names = value.into();
        self.focusable_window_names.clone()
    }

    /// Return the currently focused window id.
    #[func]
    fn get_focused_window(&mut self) -> u32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_focused_window() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get focused window: {e:?}");
                return Default::default();
            }
        };

        self.focused_window = value.unwrap_or_default();
        self.focused_window
    }

    /// Return the currently focused app id.
    #[func]
    fn get_focused_app(&mut self) -> u32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_focused_app() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get focused app: {e:?}");
                return Default::default();
            }
        };

        self.focused_app = value.unwrap_or_default();
        self.focused_app
    }

    /// Return the currently focused gfx app id.
    #[func]
    fn get_focused_app_gfx(&mut self) -> u32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_focused_app_gfx() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get focused app gfx: {e:?}");
                return Default::default();
            }
        };

        self.focused_app_gfx = value.unwrap_or_default();
        self.focused_app_gfx
    }

    /// Returns whether or not the overlay window is currently focused
    #[func]
    fn get_overlay_focused(&mut self) -> bool {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }

        let focused = match self.xwayland.is_overlay_focused() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get overlay focused: {e:?}");
                Default::default()
            }
        };
        self.overlay_focused = focused;
        self.overlay_focused
    }

    /// The current Gamescope FPS limit
    #[func]
    fn get_fps_limit(&mut self) -> u32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_fps_limit() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get fps limit: {e:?}");
                return Default::default();
            }
        };

        self.fps_limit = value.unwrap_or_default();
        self.fps_limit
    }

    /// Sets the current Gamescope FPS limit
    #[func]
    fn set_fps_limit(&mut self, fps: u32) {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return;
        }
        if let Err(e) = self.xwayland.set_fps_limit(fps) {
            log::error!("Failed to set FPS limit to {fps}: {e:?}");
        }
        self.fps_limit = fps;
    }

    /// The Gamescope blur mode (0 - off, 1 - cond, 2 - always)
    #[func]
    fn get_blur_mode(&mut self) -> u32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_blur_mode() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get blur mode: {e:?}");
                return Default::default();
            }
        };
        let Some(mode) = value else {
            return Default::default();
        };

        let blur_mode = match mode {
            BlurMode::Off => 0,
            BlurMode::Cond => 1,
            BlurMode::Always => 2,
        };
        self.blur_mode = blur_mode;
        self.blur_mode
    }

    /// Sets the Gamescope blur mode
    #[func]
    fn set_blur_mode(&mut self, mode: u32) {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let blur_mode = match mode {
            0 => BlurMode::Off,
            1 => BlurMode::Cond,
            2 => BlurMode::Always,
            _ => BlurMode::Off,
        };
        if let Err(e) = self.xwayland.set_blur_mode(blur_mode) {
            log::error!("Failed to set blur mode to: {mode}: {e:?}");
        }
        self.blur_mode = mode;
    }

    // The blur radius size
    #[func]
    fn get_blur_radius(&self) -> u32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        self.blur_radius
    }

    /// Sets the blur radius size
    #[func]
    fn set_blur_radius(&mut self, radius: u32) {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return;
        }
        if let Err(e) = self.xwayland.set_blur_radius(radius) {
            log::error!("Failed to set blur radius to: {radius}: {e:?}");
        }
        self.blur_radius = radius;
    }

    /// Whether or not Gamescope should be allowed to screen tear
    #[func]
    fn get_allow_tearing(&self) -> bool {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        self.allow_tearing
    }

    /// Sets whether or not Gamescope should be allowed to screen tear
    #[func]
    fn set_allow_tearing(&mut self, allow: bool) {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return;
        }
        if let Err(e) = self.xwayland.set_allow_tearing(allow) {
            log::error!("Failed to set allow tearing to: {allow}: {e:?}");
        }
        self.allow_tearing = allow;
    }

    /// Returns true if the window with the given window ID exists in focusable apps
    #[func]
    fn is_focusable_app(&self, window_id: u32) -> bool {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        match self.xwayland.is_focusable_app(window_id) {
            Ok(is_focusable) => is_focusable,
            Err(e) => {
                log::error!("Failed to check if window '{window_id}' is focusable app: {e:?}");
                Default::default()
            }
        }
    }

    /// Sets the given window as the main launcher app. This will set an X window
    /// property called STEAM_GAME to 769 (Steam), which will make Gamescope
    /// treat the window as the main overlay.
    #[func]
    fn set_main_app(&self, window_id: u32) -> i32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        if let Err(e) = self.xwayland.set_main_app(window_id) {
            log::error!("Failed to set window '{window_id}' as main app: {e:?}");
            return -1;
        }
        0
    }

    /// Set the given window as the primary overlay input focus. This should be set to
    /// "1" whenever the overlay wants to intercept input from a game.
    #[func]
    fn set_input_focus(&self, window_id: u32, value: u32) -> i32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        if let Err(e) = self.xwayland.set_input_focus(window_id, value) {
            log::error!("Failed to set input focus on '{window_id}' to '{value}': {e:?}");
            return -1;
        }
        0
    }

    /// Get the overlay status for the given window
    #[func]
    fn get_overlay(&self, window_id: u32) -> u32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        match self.xwayland.get_overlay(window_id) {
            Ok(value) => value.unwrap_or_default(),
            Err(e) => {
                log::error!("Failed to get overlay status for window '{window_id}': {e:?}");
                0
            }
        }
    }

    /// Set the given window as the main overlay window
    #[func]
    fn set_overlay(&self, window_id: u32, value: u32) -> i32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        if let Err(e) = self.xwayland.set_overlay(window_id, value) {
            log::error!("Failed to set overlay on '{window_id}' to '{value}': {e:?}");
            return -1;
        }
        0
    }

    /// Set the given window as a notification. This should be set to "1" when some
    /// UI wants to be shown but not intercept input.
    #[func]
    fn set_notification(&self, window_id: u32, value: u32) -> i32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        if let Err(e) = self.xwayland.set_notification(window_id, value) {
            log::error!("Failed to set notification on '{window_id}' to '{value}': {e:?}");
            return -1;
        }
        0
    }

    /// Set the given window as an external overlay window
    #[func]
    fn set_external_overlay(&self, window_id: u32, value: u32) -> i32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        if let Err(e) = self.xwayland.set_external_overlay(window_id, value) {
            log::error!("Failed to set external overlay on '{window_id}' to '{value}': {e:?}");
            return -1;
        }
        0
    }

    /// Returns the currently set manual focus
    #[func]
    fn get_baselayer_window(&mut self) -> u32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_baselayer_window() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get baselayer window: {e:?}");
                return Default::default();
            }
        };

        self.baselayer_window = value.unwrap_or_default();
        self.baselayer_window
    }

    /// Focuses the given window
    #[func]
    fn set_baselayer_window(&mut self, window_id: u32) {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return;
        }
        if let Err(e) = self.xwayland.set_baselayer_window(window_id) {
            log::error!("Failed to set baselayer window to {window_id}: {e:?}");
        }
        self.baselayer_window = window_id;
    }

    /// Removes the baselayer property to un-focus windows
    #[func]
    fn remove_baselayer_window(&mut self) {
        if let Err(e) = self.xwayland.remove_baselayer_window() {
            log::error!("Failed to remove baselayer window: {e:?}");
        }
        self.baselayer_window = 0;
    }

    /// Returns the app id of the currently manually focused app
    #[func]
    fn get_baselayer_app(&mut self) -> u32 {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return Default::default();
        }
        let value = match self.xwayland.get_baselayer_app_id() {
            Ok(value) => value,
            Err(e) => {
                log::error!("Failed to get baselayer app id: {e:?}");
                return Default::default();
            }
        };

        self.baselayer_window = value.unwrap_or_default();
        self.baselayer_window
    }

    /// Focuses the app with the given app id
    #[func]
    fn set_baselayer_app(&mut self, app_id: u32) {
        if !self.is_primary {
            log::error!("XWayland instance is not primary!");
            return;
        }
        if let Err(e) = self.xwayland.set_baselayer_app_id(app_id) {
            log::error!("Failed to set baselayer app id to {app_id}: {e:?}");
        }
        self.baselayer_window = app_id;
    }

    /// Removes the baselayer property to un-focus apps
    #[func]
    fn remove_baselayer_app(&mut self) {
        if let Err(e) = self.xwayland.remove_baselayer_app_id() {
            log::error!("Failed to remove baselayer app: {e:?}");
        }
        self.baselayer_window = 0;
    }

    /// Request a screenshot from Gamescope
    #[func]
    fn request_screenshot(&self) {
        if let Err(e) = self.xwayland.request_screenshot() {
            log::error!("Failed to request screenshot: {e:?}");
        }
    }

    /// Dispatches signals, called by [GamescopeInstance]
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
        //log::trace!("Got signal: {signal:?}");
        match signal {
            Signal::WindowCreated { window_id } => {
                self.base_mut()
                    .emit_signal("window_created", &[window_id.to_variant()]);
            }
            Signal::WindowDestroyed { window_id } => {
                self.base_mut()
                    .emit_signal("window_destroyed", &[window_id.to_variant()]);
            }
            Signal::WindowPropertyChanged {
                window_id,
                property,
            } => {
                self.base_mut().emit_signal(
                    "window_property_updated",
                    &[window_id.to_variant(), property.to_godot().to_variant()],
                );
            }
            Signal::PropertyChanged { property } => {
                match property {
                    property if property == GamescopeAtom::FocusedApp.to_string() => {
                        let from = self.focused_app;
                        let to = self.get_focused_app();
                        self.base_mut().emit_signal(
                            "focused_app_updated",
                            &[from.to_variant(), to.to_variant()],
                        );
                    }
                    property if property == GamescopeAtom::FocusedAppGFX.to_string() => {
                        let from = self.focused_app_gfx;
                        let to = self.get_focused_app_gfx();
                        self.base_mut().emit_signal(
                            "focused_app_gfx_updated",
                            &[from.to_variant(), to.to_variant()],
                        );
                    }
                    property if property == GamescopeAtom::FocusableApps.to_string() => {
                        let from = self.focusable_apps.clone();
                        let to = self.get_focusable_apps();
                        self.base_mut().emit_signal(
                            "focusable_apps_updated",
                            &[from.to_variant(), to.to_variant()],
                        );
                    }
                    property if property == GamescopeAtom::FocusedWindow.to_string() => {
                        let from = self.focused_window;
                        let to = self.get_focused_window();
                        self.base_mut().emit_signal(
                            "focused_window_updated",
                            &[from.to_variant(), to.to_variant()],
                        );
                    }
                    property if property == GamescopeAtom::FocusableWindows.to_string() => {
                        let from = self.focusable_windows.clone();
                        let to = self.get_focusable_windows();
                        self.base_mut().emit_signal(
                            "focusable_windows_updated",
                            &[from.to_variant(), to.to_variant()],
                        );
                    }
                    property if property == GamescopeAtom::BaselayerWindow.to_string() => {
                        let from = self.baselayer_window;
                        let to = self.get_baselayer_window();
                        self.base_mut().emit_signal(
                            "baselayer_window_updated",
                            &[from.to_variant(), to.to_variant()],
                        );
                    }
                    property if property == GamescopeAtom::BaselayerAppId.to_string() => {
                        let from = self.baselayer_app;
                        let to = self.get_baselayer_app();
                        self.base_mut().emit_signal(
                            "baselayer_app_updated",
                            &[from.to_variant(), to.to_variant()],
                        );
                    }
                    _ => {
                        // Unknown prop changed
                    }
                }
            }
        }
    }
}

#[godot_api]
impl IResource for GamescopeXWayland {
    fn to_string(&self) -> GString {
        format!("<GamescopeXWayland#{}>", self.name).into()
    }
}

impl Drop for GamescopeXWayland {
    fn drop(&mut self) {
        log::trace!("Gamescope XWayland '{}' is being destroyed!", self.name);
    }
}

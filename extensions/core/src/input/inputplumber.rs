pub mod composite_device;
pub mod dbus_device;
pub mod event_device;
pub mod keyboard_device;
pub mod mouse_device;

use dbus_device::DBusDevice;
use futures_util::stream::StreamExt;
use std::collections::HashMap;
use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};
use std::time::Duration;

use composite_device::CompositeDevice;
use godot::prelude::*;

use godot::classes::{Engine, Resource};
use zbus::fdo::ObjectManagerProxy;
use zbus::names::BusName;

use crate::dbus::inputplumber::input_manager::InputManagerProxyBlocking;
use crate::dbus::RunError;
use crate::{get_dbus_system, get_dbus_system_blocking, RUNTIME};

const INPUT_PLUMBER_BUS: &str = "org.shadowblip.InputPlumber";
const INPUT_PLUMBER_PATH: &str = "/org/shadowblip/InputPlumber";

/// Supported InputPlumber DBus objects
#[derive(Debug)]
enum ObjectType {
    Unknown,
    CompositeDevice,
    SourceEventDevice,
    SourceHidRawDevice,
    SourceIioDevice,
    TargetDBusDevice,
    TargetGamepadDevice,
    TargetKeyboardDevice,
    TargetMouseDevice,
}

impl ObjectType {
    fn from_dbus_path(path: &str) -> Self {
        if path.contains("CompositeDevice") {
            return Self::CompositeDevice;
        }
        if path.contains("dbus") {
            return Self::TargetDBusDevice;
        }
        if path.contains("target") && path.contains("mouse") {
            return Self::TargetMouseDevice;
        }
        if path.contains("target") && path.contains("keyboard") {
            return Self::TargetKeyboardDevice;
        }
        if path.contains("target") && path.contains("gamepad") {
            return Self::TargetGamepadDevice;
        }
        if path.contains("source") && path.contains("event") {
            return Self::SourceEventDevice;
        }
        if path.contains("source") && path.contains("hidraw") {
            return Self::SourceHidRawDevice;
        }
        if path.contains("source") && path.contains("iio") {
            return Self::SourceIioDevice;
        }
        Self::Unknown
    }
}

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Started,
    Stopped,
    ObjectAdded { path: String, kind: ObjectType },
    ObjectRemoved { path: String, kind: ObjectType },
}

/// Instance representing a client connection to InputPlumber over DBus. This
/// is represented as a resource so it can be accessed from anywhere in the scene
/// tree, but there must be a node that calls 'process()' on this resource every
/// frame in order to emit signals and process messages.
#[derive(GodotClass)]
#[class(base=Resource)]
pub struct InputPlumberInstance {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,
    /// Map of DBus path to composite device resource. E.g.
    /// {"/org/shadowblip/InputPlumber/CompositeDevice0": <CompositeDevice>}
    composite_devices: HashMap<String, Gd<CompositeDevice>>,
    /// Map of DBus path to dbus device resource. E.g.
    /// {"/org/shadowblip/InputPlumber/target/dbus0": <DBusDevice>}
    dbus_devices: HashMap<String, Gd<DBusDevice>>,
    /// The current intercept mode set for all devices
    #[var(get = get_intercept_mode, set = set_intercept_mode)]
    intercept_mode: i64,
    /// The current events that will trigger intercept mode
    #[var(get = get_intercept_triggers, set = set_intercept_triggers)]
    intercept_triggers: PackedStringArray,
    /// The current target event for intercept mode
    #[var(get = get_intercept_target, set = set_intercept_target)]
    intercept_target: GString,
    /// Whether or not to automatically manage all supported input devices
    #[allow(dead_code)]
    #[var(get = get_manage_all_devices, set = set_manage_all_devices)]
    manage_all_devices: bool,
}

#[godot_api]
impl InputPlumberInstance {
    #[constant]
    const INTERCEPT_MODE_NONE: i32 = 0;
    #[constant]
    const INTERCEPT_MODE_PASS: i32 = 1;
    #[constant]
    const INTERCEPT_MODE_ALL: i32 = 2;

    /// Emitted when InputPlumber is detected as running
    #[signal]
    fn started();

    /// Emitted when InputPlumber is detected as stopped
    #[signal]
    fn stopped();

    /// Emitted when a CompositeDevice is dicovered and identified as a new device
    #[signal]
    fn composite_device_added(device: Gd<CompositeDevice>);

    /// Emitted when a CompositeDevice is removed
    #[signal]
    fn composite_device_removed(dbus_path: GString);

    /// Return a proxy instance to the input manager
    fn get_proxy(&self) -> Option<InputManagerProxyBlocking> {
        if let Some(conn) = self.conn.as_ref() {
            InputManagerProxyBlocking::builder(conn).build().ok()
        } else {
            None
        }
    }

    /// Returns true if the InputPlumber service is currently running
    #[func]
    fn is_running(&self) -> bool {
        let Some(conn) = self.conn.as_ref() else {
            return false;
        };
        let bus = BusName::from_static_str(INPUT_PLUMBER_BUS).unwrap();
        let dbus = zbus::blocking::fdo::DBusProxy::new(conn).ok();
        let Some(dbus) = dbus else {
            return false;
        };
        dbus.name_has_owner(bus.clone()).unwrap_or_default()
    }

    /// Returns the [CompositeDevice] with the given DBus path. If the device
    /// does not exist, null will be returned.
    #[func]
    fn get_composite_device(&self, dbus_path: GString) -> Option<Gd<CompositeDevice>> {
        let path = String::from(dbus_path);
        let device = self.composite_devices.get(&path)?;
        Some(device.clone())
    }

    /// Return all current composite devices
    #[func]
    fn get_composite_devices(&mut self) -> Array<Gd<CompositeDevice>> {
        let mut devices = array![];
        let objects = match self.get_managed_objects() {
            Ok(paths) => paths,
            Err(e) => {
                log::error!("Failed to get managed objects: {e:?}");
                return devices;
            }
        };

        for path in objects {
            if !path.contains("CompositeDevice") {
                continue;
            }
            let device = CompositeDevice::new(path.as_str());
            devices.push(&device);
        }

        devices
    }

    /// Returns the [DBusDevice] with the given DBus path. If the device
    /// does not exist, null will be returned.
    #[func]
    fn get_dbus_device(&self, dbus_path: GString) -> Option<Gd<DBusDevice>> {
        let path = String::from(dbus_path);
        let device = self.dbus_devices.get(&path)?;
        Some(device.clone())
    }

    /// Return all current dbus devices
    #[func]
    fn get_dbus_devices(&mut self) -> Array<Gd<DBusDevice>> {
        let mut devices = array![];
        let objects = match self.get_managed_objects() {
            Ok(paths) => paths,
            Err(e) => {
                log::error!("Failed to get managed objects: {e:?}");
                return devices;
            }
        };

        for path in objects {
            if !path.contains("target/dbus") {
                continue;
            }
            let device = DBusDevice::new(path.as_str());
            devices.push(&device);
        }

        devices
    }

    /// Get managed objects
    fn get_managed_objects(&self) -> Result<Vec<String>, zbus::fdo::Error> {
        let Some(conn) = self.conn.as_ref() else {
            return Err(zbus::fdo::Error::Disconnected(
                "No DBus connection found".into(),
            ));
        };

        let bus = BusName::from_static_str(INPUT_PLUMBER_BUS).unwrap();
        let object_manager = zbus::blocking::fdo::ObjectManagerProxy::builder(conn)
            .destination(bus)
            .ok()
            .and_then(|builder| builder.path(INPUT_PLUMBER_PATH).ok())
            .and_then(|builder| builder.build().ok());
        let Some(object_manager) = object_manager else {
            return Ok(Vec::new());
        };

        Ok(object_manager
            .get_managed_objects()?
            .keys()
            .map(|v| v.to_string())
            .collect())
    }

    /// Process InputPlumber signals and emit them as Godot signals. This method
    /// should be called every frame in the "_process" loop of a node.
    #[func]
    fn process(&mut self) {
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

        // Process signals from tracked devices
        for (_, device) in self.dbus_devices.iter_mut() {
            device.bind_mut().process();
        }
        for (_, device) in self.composite_devices.iter_mut() {
            device.bind_mut().process();
        }
    }

    /// Gets whether or not InputPlumber should automatically manage all supported devices
    #[func]
    fn get_manage_all_devices(&self) -> bool {
        let Some(proxy) = self.get_proxy() else {
            return false;
        };
        proxy.manage_all_devices().unwrap_or_default()
    }

    /// Sets whether or not InputPlumber should automatically manage all supported devices
    #[func]
    fn set_manage_all_devices(&self, value: bool) {
        let Some(proxy) = self.get_proxy() else {
            return;
        };
        proxy.set_manage_all_devices(value).unwrap_or_default()
    }

    /// Gets the current intercept mode for all composite devices
    #[func]
    fn get_intercept_mode(&self) -> i64 {
        self.intercept_mode
    }

    /// Sets all composite devices to the specified intercept mode.
    #[func]
    fn set_intercept_mode(&mut self, mode: i64) {
        if !(0..=2).contains(&mode) {
            log::error!("Invalid intercept mode: {mode}");
            return;
        }
        self.intercept_mode = mode;
        for (_, device) in self.composite_devices.iter() {
            device.bind().set_intercept_mode(mode as i32);
        }
    }

    /// Gets the current triggers for activating intercept mode for all devices
    #[func]
    fn get_intercept_triggers(&self) -> PackedStringArray {
        self.intercept_triggers.clone()
    }

    /// Sets the current triggers for activating intercept mode for all devices
    #[func]
    fn set_intercept_triggers(&mut self, triggers: PackedStringArray) {
        self.intercept_triggers = triggers;
    }

    /// Gets the current target event for activating intercept mode for all devices
    #[func]
    fn get_intercept_target(&self) -> GString {
        self.intercept_target.clone()
    }

    /// Sets the current target event for activating intercept mode for all devices
    #[func]
    fn set_intercept_target(&mut self, target_event: GString) {
        self.intercept_target = target_event;
    }

    /// Sets all composite devices to use the specified intercept actions.
    #[func]
    fn set_intercept_activation(&mut self, triggers: PackedStringArray, target_event: GString) {
        self.set_intercept_triggers(triggers.clone());
        self.set_intercept_target(target_event.clone());
        for (_, device) in self.composite_devices.iter() {
            device
                .bind()
                .set_intercept_activation(triggers.clone(), target_event.clone())
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::Started => {
                self.base_mut().emit_signal("started", &[]);
            }
            Signal::Stopped => {
                // Clear all known devices
                self.composite_devices.clear();
                self.dbus_devices.clear();
                self.base_mut().emit_signal("stopped", &[]);
            }
            Signal::ObjectAdded { path, kind } => {
                self.on_object_added(path, kind);
            }
            Signal::ObjectRemoved { path, kind } => {
                self.on_object_removed(path, kind);
            }
        }
    }

    /// Track the given object and emit signals
    fn on_object_added(&mut self, path: String, kind: ObjectType) {
        match kind {
            ObjectType::Unknown => (),
            ObjectType::CompositeDevice => {
                log::debug!("CompositeDevice added: {path}");
                let device = CompositeDevice::new(path.as_str());
                self.composite_devices.insert(path, device.clone());
                self.base_mut()
                    .emit_signal("composite_device_added", &[device.to_variant()]);
            }
            ObjectType::SourceEventDevice => (),
            ObjectType::SourceHidRawDevice => (),
            ObjectType::SourceIioDevice => (),
            ObjectType::TargetDBusDevice => {
                log::debug!("DBusDevice added: {path}");
                let device = DBusDevice::new(path.as_str());
                self.dbus_devices.insert(path, device);
            }
            ObjectType::TargetGamepadDevice => (),
            ObjectType::TargetKeyboardDevice => (),
            ObjectType::TargetMouseDevice => (),
        }
    }

    /// Remove the given object and emit signals
    fn on_object_removed(&mut self, path: String, kind: ObjectType) {
        match kind {
            ObjectType::Unknown => (),
            ObjectType::CompositeDevice => {
                log::debug!("CompositeDevice device removed: {path}");
                self.composite_devices.remove(&path);
                self.base_mut().emit_signal(
                    "composite_device_removed",
                    &[GString::from(path).to_variant()],
                );
            }
            ObjectType::SourceEventDevice => (),
            ObjectType::SourceHidRawDevice => (),
            ObjectType::SourceIioDevice => (),
            ObjectType::TargetDBusDevice => {
                log::debug!("DBusDevice device removed: {path}");
                self.dbus_devices.remove(&path);
            }
            ObjectType::TargetGamepadDevice => (),
            ObjectType::TargetKeyboardDevice => (),
            ObjectType::TargetMouseDevice => (),
        }
    }
}

#[godot_api]
impl IResource for InputPlumberInstance {
    /// Called upon object initialization in the engine
    fn init(base: Base<Self::Base>) -> Self {
        log::debug!("Initializing InputPlumber instance");

        // Create a channel to communicate with the service
        let (tx, rx) = channel();
        let conn = get_dbus_system_blocking().ok();

        // Don't run in the editor
        let engine = Engine::singleton();
        if engine.is_editor_hint() {
            return Self {
                base,
                rx,
                conn,
                composite_devices: Default::default(),
                dbus_devices: Default::default(),
                intercept_mode: Default::default(),
                intercept_triggers: Default::default(),
                intercept_target: Default::default(),
                manage_all_devices: Default::default(),
            };
        }

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx).await {
                log::error!("Failed to run InputPlumber task: ${e:?}");
            }
        });

        // Create a new InputPlumber instance
        let mut instance = Self {
            base,
            rx,
            conn,
            composite_devices: HashMap::new(),
            dbus_devices: HashMap::new(),
            intercept_mode: 0,
            intercept_triggers: PackedStringArray::from(&["Gamepad:Button:Guide".into()]),
            intercept_target: "Gamepad:Button:Guide".into(),
            manage_all_devices: Default::default(),
        };

        // Do initial device discovery
        let devices = instance.get_composite_devices();
        for device in devices.iter_shared() {
            let path = device.bind().get_dbus_path();
            instance.composite_devices.insert(path.into(), device);
        }
        let dbus_devices = instance.get_dbus_devices();
        for dbus_device in dbus_devices.iter_shared() {
            let path = dbus_device.bind().get_dbus_path();
            instance
                .dbus_devices
                .insert(path.into(), dbus_device.clone());
        }
        instance
    }
}

/// Runs InputPlumber tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>) -> Result<(), RunError> {
    log::debug!("Spawning inputplumber");
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;

    // Spawn a task to listen for InputPlumber start/stop
    let dbus_conn = conn.clone();
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        let bus = BusName::from_static_str(INPUT_PLUMBER_BUS).unwrap();
        let mut is_running = {
            let dbus = zbus::fdo::DBusProxy::new(&dbus_conn).await.ok();
            let Some(dbus) = dbus else {
                return;
            };
            dbus.name_has_owner(bus.clone()).await.unwrap_or_default()
        };

        loop {
            let dbus = zbus::fdo::DBusProxy::new(&dbus_conn).await.ok();
            let Some(dbus) = dbus else {
                break;
            };
            let running = dbus.name_has_owner(bus.clone()).await.unwrap_or_default();
            if running != is_running {
                let signal = if running {
                    Signal::Started
                } else {
                    Signal::Stopped
                };
                if signals_tx.send(signal).is_err() {
                    break;
                }
            }
            is_running = running;
            tokio::time::sleep(Duration::from_secs(5)).await;
        }
    });

    // Get a proxy instance to ObjectManager
    let bus = BusName::from_static_str(INPUT_PLUMBER_BUS).unwrap();
    let object_manager: ObjectManagerProxy = ObjectManagerProxy::builder(&conn)
        .destination(bus)?
        .path(INPUT_PLUMBER_PATH)?
        .build()
        .await?;

    // Spawn a task to listen for objects added
    let mut ifaces_added = object_manager.receive_interfaces_added().await?;
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        while let Some(signal) = ifaces_added.next().await {
            let args = match signal.args() {
                Ok(args) => args,
                Err(e) => {
                    log::warn!("Failed to get signal args: ${e:?}");
                    continue;
                }
            };

            let path = args.object_path.to_string();
            let kind = ObjectType::from_dbus_path(path.as_str());
            let signal = Signal::ObjectAdded { path, kind };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    // Spawn a task to listen for objects removed
    let mut ifaces_removed = object_manager.receive_interfaces_removed().await?;
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        while let Some(signal) = ifaces_removed.next().await {
            let args = match signal.args() {
                Ok(args) => args,
                Err(e) => {
                    log::warn!("Failed to get signal args: ${e:?}");
                    continue;
                }
            };

            let path = args.object_path.to_string();
            let kind = ObjectType::from_dbus_path(path.as_str());
            let signal = Signal::ObjectRemoved { path, kind };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    Ok(())
}

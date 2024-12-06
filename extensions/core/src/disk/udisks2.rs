pub mod block_device;
pub mod drive_device;
pub mod filesystem_device;
pub mod partition_device;

use std::{
    collections::HashMap,
    sync::mpsc::{channel, Receiver, Sender, TryRecvError},
    time::Duration,
};

use block_device::BlockDevice;
use drive_device::DriveDevice;
use filesystem_device::FilesystemDevice;
use futures_util::stream::StreamExt;
use godot::{classes::Engine, obj::WithBaseField, prelude::*};
use partition_device::PartitionDevice;
use zbus::fdo::{ManagedObjects, ObjectManagerProxy};
use zbus::names::BusName;

use crate::{dbus::RunError, get_dbus_system, get_dbus_system_blocking, RUNTIME};

pub const UDISKS2_BUS: &str = "org.freedesktop.UDisks2";
const UDISKS2_PATH: &str = "/org/freedesktop/UDisks2";

/// List of mount points that should not be considered for formatting
const PROTECTED_MOUNTS: [&str; 10] = [
    "/",
    "/boot",
    "/boot/efi",
    "/efi",
    "/frzr_root",
    "/frzr_root/boot",
    "/home",
    "/var",
    "/var/cache",
    "/var/log",
];

/// Supported UDisks2 DBus objects
#[derive(Debug, Clone, Copy)]
enum ObjectType {
    Block,
    Drive,
    Partition,
    Filesystem,
}

impl ObjectType {
    /// Returns the object type(s) from the list of implemented interfaces
    fn from_ifaces(ifaces: Vec<String>) -> Vec<Self> {
        let mut types = vec![];

        for iface in ifaces {
            if iface.as_str() == "org.freedesktop.UDisks2.Drive" {
                types.push(Self::Drive);
            }
            if iface.as_str() == "org.freedesktop.UDisks2.Block" {
                types.push(Self::Block);
            }
            if iface.as_str() == "org.freedesktop.UDisks2.Partition" {
                types.push(Self::Partition);
            }
            if iface.as_str() == "org.freedesktop.UDisks2.Filesystem" {
                types.push(Self::Filesystem);
            }
        }

        types
    }
}

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Started,
    Stopped,
    ObjectAdded { path: String, ifaces: Vec<String> },
    ObjectRemoved { path: String, ifaces: Vec<String> },
}

#[derive(GodotClass)]
#[class(base=Resource)]
pub struct UDisks2Instance {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,
    drive_devices: HashMap<String, Gd<DriveDevice>>,
    block_devices: HashMap<String, Gd<BlockDevice>>,
    partition_devices: HashMap<String, Gd<PartitionDevice>>,
    filesystem_devices: HashMap<String, Gd<FilesystemDevice>>,
}

#[godot_api]
impl UDisks2Instance {
    /// Emitted when UDisks2 is detected as running
    #[signal]
    fn started();

    /// Emitted when UDisks2 is detected as stopped
    #[signal]
    fn stopped();

    #[signal]
    fn drive_device_added(drive: Gd<DriveDevice>);

    #[signal]
    fn drive_device_removed(dbus_path: GString);

    #[signal]
    fn block_device_added(block: Gd<BlockDevice>);

    #[signal]
    fn block_device_removed(dbus_path: GString);

    #[signal]
    fn partition_added(partition: Gd<PartitionDevice>);

    #[signal]
    fn partition_removed(dbus_path: GString);

    #[signal]
    fn filesystem_added(filesystem: Gd<FilesystemDevice>);

    #[signal]
    fn filesystem_removed(dbus_path: GString);

    /// Emitted when any state change occurs and emits an [Array] of [BlockDevice] that have no
    /// [FilesystemDevice] with mounts located in [PROTECTED_MOUNTS].
    #[signal]
    fn unprotected_devices_updated(devices: Array<Gd<BlockDevice>>);

    /// Returns true if the UDisks2 service is currently running
    #[func]
    fn is_running(&self) -> bool {
        let Some(conn) = self.conn.as_ref() else {
            return false;
        };
        let bus = BusName::from_static_str(UDISKS2_BUS).unwrap();
        let dbus = zbus::blocking::fdo::DBusProxy::new(conn).ok();
        let Some(dbus) = dbus else {
            return false;
        };
        dbus.name_has_owner(bus.clone()).unwrap_or_default()
    }

    /// Returns a HashMap of all the objects managed by this dbus interface
    fn get_managed_objects(&self) -> Result<ManagedObjects, zbus::fdo::Error> {
        let Some(conn) = self.conn.as_ref() else {
            return Err(zbus::fdo::Error::Disconnected(
                "No DBus connection found".into(),
            ));
        };

        let bus = BusName::from_static_str(UDISKS2_BUS).unwrap();
        let object_manager = zbus::blocking::fdo::ObjectManagerProxy::builder(conn)
            .destination(bus)
            .ok()
            .and_then(|builder| builder.path(UDISKS2_PATH).ok())
            .and_then(|builder| builder.build().ok());
        let Some(object_manager) = object_manager else {
            return Ok(ManagedObjects::new());
        };

        object_manager.get_managed_objects()
    }

    /// Returns a HashMap of all the objects managed by this dbus interface that don't have
    /// [FilesystemDevice] objects with mounts in [PROTECTED_MOUNTS]
    #[func]
    fn get_unprotected_devices(&self) -> Array<Gd<BlockDevice>> {
        let mut unprotected_devices = array![];
        'outer: for (dbus_path, block_device) in self.block_devices.iter() {
            let partitions = block_device.bind().get_partitions();
            if partitions.is_empty() {
                if !self.partition_devices.contains_key(dbus_path) {
                    log::debug!(
                        "Adding {dbus_path} as unprotected device. It is not a partition_devices"
                    );
                    unprotected_devices.push(block_device);
                    continue;
                }
                log::debug!("Skipping {dbus_path}. It is a partition_device.");
            } else {
                for partition_device in partitions.iter_shared() {
                    let Some(filesystem_device) = partition_device.bind().get_filesystem() else {
                        log::debug!(
                            "Adding {dbus_path} as unprotected device. It does not have a FilesystemDevice"
                        );
                        unprotected_devices.push(block_device);
                        continue;
                    };

                    let mounts = filesystem_device.bind().get_mounts();
                    for mount in mounts.as_slice() {
                        if PROTECTED_MOUNTS.contains(&mount.to_string().as_str()) {
                            continue 'outer;
                        }
                    }
                }
                log::debug!(
                    "Adding {dbus_path} as unprotected device. It does not have any mounts in PROTECTED_MOUNTS"
                );
                unprotected_devices.push(block_device);
            }
        }

        unprotected_devices
    }

    /// Process UDisks2 signals and emit them as Godot signals. This method
    /// should be called every frame in the "_process" loop of a node.
    #[func]
    fn process(&mut self) {
        let mut state_updated = false;
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
            state_updated = true;
            self.process_signal(signal);
        }
        if !state_updated {
            return;
        }
        let unprotected_devices = self.get_unprotected_devices();
        self.base_mut().emit_signal(
            "unprotected_devices_updated",
            &[unprotected_devices.to_variant()],
        );
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::Started => {
                self.base_mut().emit_signal("started", &[]);
            }
            Signal::Stopped => {
                self.base_mut().emit_signal("stopped", &[]);
            }
            Signal::ObjectAdded { path, ifaces } => {
                let obj_types = ObjectType::from_ifaces(ifaces);
                for obj_type in obj_types {
                    match obj_type {
                        ObjectType::Block => {
                            let block = BlockDevice::new(path.as_str());
                            self.block_devices.insert(path.clone(), block.clone());
                            self.base_mut()
                                .emit_signal("block_device_added", &[block.to_variant()]);
                        }
                        ObjectType::Drive => {
                            let drive = DriveDevice::new(path.as_str());
                            self.drive_devices.insert(path.clone(), drive.clone());
                            self.base_mut()
                                .emit_signal("drive_device_added", &[drive.to_variant()]);
                        }
                        ObjectType::Partition => {
                            let partition = PartitionDevice::new(path.as_str());
                            self.partition_devices
                                .insert(path.clone(), partition.clone());
                            self.base_mut()
                                .emit_signal("partition_added", &[partition.to_variant()]);
                        }
                        ObjectType::Filesystem => {
                            let fs = FilesystemDevice::new(path.as_str());
                            self.filesystem_devices.insert(path.clone(), fs.clone());
                            self.base_mut()
                                .emit_signal("filesystem_added", &[fs.to_variant()]);
                        }
                    }
                }
            }
            Signal::ObjectRemoved { path, ifaces } => {
                let obj_types = ObjectType::from_ifaces(ifaces);
                for obj_type in obj_types {
                    match obj_type {
                        ObjectType::Block => {
                            self.block_devices.remove(&path);
                            self.base_mut()
                                .emit_signal("block_device_removed", &[path.to_variant()]);
                        }
                        ObjectType::Drive => {
                            self.drive_devices.remove(&path);
                            self.base_mut()
                                .emit_signal("drive_device_removed", &[path.to_variant()]);
                        }
                        ObjectType::Partition => {
                            self.partition_devices.remove(&path);
                            self.base_mut()
                                .emit_signal("partition_removed", &[path.to_variant()]);
                        }
                        ObjectType::Filesystem => {
                            self.filesystem_devices.remove(&path);
                            self.base_mut()
                                .emit_signal("filesystem_removed", &[path.to_variant()]);
                        }
                    }
                }
            }
        }
    }
}

#[godot_api]
impl IResource for UDisks2Instance {
    /// Called upon object initialization in the engine
    fn init(base: Base<Self::Base>) -> Self {
        log::debug!("Initializing UDisks2 instance");

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
                block_devices: Default::default(),
                drive_devices: Default::default(),
                partition_devices: Default::default(),
                filesystem_devices: Default::default(),
            };
        }

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx).await {
                log::error!("Failed to run UDisks2 task: ${e:?}");
            }
        });

        // Create a new UDisks2 instance
        let mut instance = Self {
            base,
            rx,
            conn,
            block_devices: HashMap::new(),
            drive_devices: HashMap::new(),
            partition_devices: HashMap::new(),
            filesystem_devices: HashMap::new(),
        };

        // Perform initial object discovery
        let mut block_devices = HashMap::new();
        let mut drive_devices = HashMap::new();
        let mut partition_devices = HashMap::new();
        let mut filesystem_devices = HashMap::new();
        let objects = instance.get_managed_objects().unwrap_or_default();
        for (path, ifaces) in objects.into_iter() {
            let path = path.to_string();
            let ifaces: Vec<String> = ifaces.into_keys().map(|v| v.to_string()).collect();
            let obj_types = ObjectType::from_ifaces(ifaces);

            for obj_type in obj_types {
                match obj_type {
                    ObjectType::Block => {
                        let block = BlockDevice::new(path.as_str());
                        block_devices.insert(path.clone(), block);
                    }
                    ObjectType::Drive => {
                        let drive = DriveDevice::new(path.as_str());
                        drive_devices.insert(path.clone(), drive);
                    }
                    ObjectType::Partition => {
                        let partition = PartitionDevice::new(path.as_str());
                        partition_devices.insert(path.clone(), partition);
                    }
                    ObjectType::Filesystem => {
                        let fs = FilesystemDevice::new(path.as_str());
                        filesystem_devices.insert(path.clone(), fs);
                    }
                }
            }
        }
        instance.block_devices = block_devices;
        instance.drive_devices = drive_devices;
        instance.partition_devices = partition_devices;
        instance.filesystem_devices = filesystem_devices;

        instance
    }
}

/// Runs UDisks2 tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>) -> Result<(), RunError> {
    log::debug!("Spawning UDisks2 tasks");
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;

    // Spawn a task to listen for UDisks2 start/stop
    let dbus_conn = conn.clone();
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        let bus = BusName::from_static_str(UDISKS2_BUS).unwrap();
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
    let bus = BusName::from_static_str(UDISKS2_BUS).unwrap();
    let object_manager: ObjectManagerProxy = ObjectManagerProxy::builder(&conn)
        .destination(bus)?
        .path(UDISKS2_PATH)?
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
            let ifaces = args
                .interfaces_and_properties
                .keys()
                .map(|v| v.to_string())
                .collect();
            let signal = Signal::ObjectAdded { path, ifaces };
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
            let ifaces = args.interfaces.iter().map(|v| v.to_string()).collect();
            let signal = Signal::ObjectRemoved { path, ifaces };
            if signals_tx.send(signal).is_err() {
                break;
            }
        }
    });

    Ok(())
}

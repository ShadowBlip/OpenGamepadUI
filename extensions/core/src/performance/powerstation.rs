pub mod cpu;
pub mod cpu_core;
pub mod gpu;
pub mod gpu_card;
pub mod gpu_connector;

use std::{
    sync::mpsc::{channel, Receiver, Sender, TryRecvError},
    time::Duration,
};

use cpu::Cpu;
use godot::{classes::Engine, prelude::*};
use gpu::Gpu;
use zbus::names::BusName;

use crate::{dbus::RunError, get_dbus_system, get_dbus_system_blocking, RUNTIME};

pub const POWERSTATION_BUS: &str = "org.shadowblip.PowerStation";
const POWERSTATION_CPU_PATH: &str = "/org/shadowblip/Performance/CPU";
const POWERSTATION_GPU_PATH: &str = "/org/shadowblip/Performance/GPU";

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Started,
    Stopped,
}

/// PowerStation dbus proxy
#[derive(GodotClass)]
#[class(base=Resource)]
pub struct PowerStationInstance {
    base: Base<Resource>,
    rx: Receiver<Signal>,
    conn: Option<zbus::blocking::Connection>,
    cpu_instance: Option<Gd<Cpu>>,
    gpu_instance: Option<Gd<Gpu>>,

    #[allow(dead_code)]
    #[var(get = get_cpu)]
    cpu: Option<Gd<Cpu>>,
    #[allow(dead_code)]
    #[var(get = get_gpu)]
    gpu: Option<Gd<Gpu>>,
}

#[godot_api]
impl PowerStationInstance {
    /// Emitted when PowerStation is detected as running
    #[signal]
    fn started();

    /// Emitted when PowerStation is detected as stopped
    #[signal]
    fn stopped();

    /// Returns true if the PowerStation service is currently running
    #[func]
    fn is_running(&self) -> bool {
        let Some(conn) = self.conn.as_ref() else {
            return false;
        };
        let bus = BusName::from_static_str(POWERSTATION_BUS).unwrap();
        let dbus = zbus::blocking::fdo::DBusProxy::new(conn).ok();
        let Some(dbus) = dbus else {
            return false;
        };
        dbus.name_has_owner(bus.clone()).unwrap_or_default()
    }

    /// Returns an instance of the CPU
    #[func]
    fn get_cpu(&self) -> Option<Gd<Cpu>> {
        self.cpu_instance.clone()
    }

    /// Returns an instance of the GPU
    #[func]
    fn get_gpu(&self) -> Option<Gd<Gpu>> {
        self.gpu_instance.clone()
    }

    /// Process UPower signals and emit them as Godot signals. This method
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

        // Process any signals for the CPU instance
        if let Some(cpu) = self.cpu_instance.as_mut() {
            cpu.bind_mut().process();
        }
        // Process any signals for the GPU instance
        if let Some(gpu) = self.gpu_instance.as_mut() {
            gpu.bind_mut().process();
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::Started => {
                // Create an instance for the CPU
                self.cpu_instance = Some(Cpu::new(POWERSTATION_CPU_PATH));
                self.base_mut().emit_signal("started", &[]);
            }
            Signal::Stopped => {
                self.cpu_instance = None;
                self.base_mut().emit_signal("stopped", &[]);
            }
        }
    }
}

#[godot_api]
impl IResource for PowerStationInstance {
    /// Called upon object initialization in the engine
    fn init(base: Base<Self::Base>) -> Self {
        log::debug!("Initializing PowerStation instance");

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
                cpu_instance: Default::default(),
                gpu_instance: Default::default(),
                cpu: Default::default(),
                gpu: Default::default(),
            };
        }

        // Spawn a task using the shared tokio runtime to listen for signals
        RUNTIME.spawn(async move {
            if let Err(e) = run(tx).await {
                log::error!("Failed to run PowerStation task: ${e:?}");
            }
        });

        // Create CPU instance
        let cpu = Some(Cpu::new(POWERSTATION_CPU_PATH));
        // Create GPU instance
        let gpu = Some(Gpu::new(POWERSTATION_GPU_PATH));

        // Create a new PowerStation instance
        Self {
            base,
            rx,
            conn,
            cpu_instance: cpu,
            gpu_instance: gpu,
            cpu: None,
            gpu: None,
        }
    }
}

/// Runs PowerStation tasks in Tokio to listen for DBus signals and send them
/// over the given channel so they can be processed during each engine frame.
async fn run(tx: Sender<Signal>) -> Result<(), RunError> {
    log::debug!("Spawning PowerStation tasks");
    // Establish a connection to the system bus
    let conn = get_dbus_system().await?;

    // Spawn a task to listen for PowerStation start/stop
    let dbus_conn = conn.clone();
    let signals_tx = tx.clone();
    RUNTIME.spawn(async move {
        let bus = BusName::from_static_str(POWERSTATION_BUS).unwrap();
        let mut is_running = {
            let dbus = zbus::fdo::DBusProxy::new(&dbus_conn).await.ok();
            let Some(dbus) = dbus else {
                return;
            };
            dbus.name_has_owner(bus.clone()).await.unwrap_or_default()
        };
        let signal = if is_running {
            Signal::Started
        } else {
            Signal::Stopped
        };
        if signals_tx.send(signal).is_err() {
            return;
        }

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

    Ok(())
}

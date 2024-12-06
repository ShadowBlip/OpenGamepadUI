pub mod bluetooth;
pub mod dbus;
pub mod disk;
pub mod gamescope;
pub mod input;
pub mod logger;
pub mod network;
pub mod performance;
pub mod power;
pub mod resource;
pub mod system;
pub mod vdf;

use std::{sync::Arc, time::Duration};

use godot::prelude::*;
use once_cell::sync::Lazy;
use tokio::{
    runtime::{Builder, Handle},
    sync::{
        mpsc::{channel, Receiver, Sender},
        Mutex,
    },
};
use zbus::{
    blocking::{self},
    Connection,
};

/// Channel for shutting down the tokio runtime
type Channel = (Sender<()>, Arc<Mutex<Receiver<()>>>);

/// Global tokio runtime instance
pub static RUNTIME: Lazy<Handle> = Lazy::new(tokio_init);
/// Shared connection to the DBus system bus
static DBUS_SYSTEM: Lazy<Arc<Mutex<Option<Connection>>>> = Lazy::new(dbus_system_init);
/// Shared blocking connection to the DBus system bus
static DBUS_SYSTEM_BLOCKING: Lazy<Option<blocking::Connection>> =
    Lazy::new(dbus_system_blocking_init);
/// Channel used to signal shutting down tokio runtime
static CHANNEL: Lazy<Channel> = Lazy::new(get_channel);

struct OpenGamepadUICore {}

#[gdextension]
unsafe impl ExtensionLibrary for OpenGamepadUICore {
    fn on_level_init(level: InitLevel) {
        if level != InitLevel::Scene {
            return;
        }
        logger::init();
        log::info!("Initializing OpenGamepadUI Core");
    }

    fn on_level_deinit(level: InitLevel) {
        if level != InitLevel::Scene {
            return;
        }
        log::info!("De-initializing OpenGamepadUI Core");
        tokio_deinit();
    }
}

fn tokio_init() -> Handle {
    log::debug!("Initializing tokio runtime");
    let runtime = Builder::new_multi_thread().enable_all().build().unwrap();
    let handle = runtime.handle().clone();

    let rx = CHANNEL.1.clone();

    std::thread::spawn(move || {
        runtime.block_on(async {
            log::debug!("Tokio runtime started");
            let _ = rx.lock().await.recv().await;
        });
        log::debug!("Shutting down Tokio runtime");
        runtime.shutdown_timeout(Duration::from_secs(1));
        log::debug!("Tokio runtime stopped");
    });

    handle
}

fn tokio_deinit() {
    let result = CHANNEL.0.clone().blocking_send(());
    if let Err(e) = result {
        log::error!("Failed to shut down tokio runtime: {e}");
    }
}

fn get_channel() -> (Sender<()>, Arc<Mutex<Receiver<()>>>) {
    let (tx, rx) = channel(1);
    (tx, Arc::new(Mutex::new(rx)))
}

fn dbus_system_init() -> Arc<Mutex<Option<Connection>>> {
    Arc::new(Mutex::new(None))
}

fn dbus_system_blocking_init() -> Option<blocking::Connection> {
    blocking::Connection::system().ok()
}

/// Return or create a shared connection to the DBus system bus
pub async fn get_dbus_system() -> Result<Connection, zbus::Error> {
    let mut conn = DBUS_SYSTEM.lock().await;
    if conn.is_some() {
        let conn_clone = conn.as_ref().unwrap().clone();
        Ok(conn_clone)
    } else {
        let new_conn = Connection::system().await?;
        let conn_clone = new_conn.clone();
        *conn = Some(new_conn);
        Ok(conn_clone)
    }
}

/// Return or create a shared blocking connection to the DBus system bus
pub fn get_dbus_system_blocking() -> Result<blocking::Connection, zbus::Error> {
    if let Some(conn) = DBUS_SYSTEM_BLOCKING.as_ref() {
        return Ok(conn.clone());
    }
    blocking::Connection::system()
}

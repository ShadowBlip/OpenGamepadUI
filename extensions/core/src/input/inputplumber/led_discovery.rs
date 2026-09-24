//! Owner-pinned LED discovery. Updates are coalesced, never queued per frame.
use super::{INPUT_PLUMBER_BUS, INPUT_PLUMBER_PATH};
use crate::{dbus::inputplumber::led_device::LED_INTERFACE, get_dbus_system, RUNTIME};
use futures_util::StreamExt;
use std::{collections::BTreeSet, time::Duration};
use tokio::{sync::watch, task::JoinHandle};
use zbus::{
    fdo::{DBusProxy, ObjectManagerProxy},
    names::BusName,
    Connection,
};

#[derive(Clone, Debug, Default, PartialEq)]
pub struct Discovery {
    pub owner: String,
    pub paths: BTreeSet<String>,
}
const TIMEOUT: Duration = Duration::from_secs(3);

pub fn start() -> (watch::Receiver<Discovery>, JoinHandle<()>) {
    let (tx, rx) = watch::channel(Discovery::default());
    let task = RUNTIME.spawn(async move {
        loop {
            if tx.is_closed() {
                return;
            }
            let result = match get_dbus_system().await {
                Ok(connection) => run(&connection, &tx).await,
                Err(error) => Err(error.to_string()),
            };
            if tx.is_closed() {
                return;
            }
            tx.send_replace(Discovery::default());
            if let Err(error) = result {
                log::warn!("LED discovery unavailable: {error}");
            }
            tokio::time::sleep(Duration::from_secs(5)).await;
        }
    });
    (rx, task)
}

pub(super) async fn run(
    connection: &Connection,
    tx: &watch::Sender<Discovery>,
) -> Result<(), String> {
    let dbus = DBusProxy::new(connection)
        .await
        .map_err(|e| e.to_string())?;
    let mut owners = dbus
        .receive_name_owner_changed_with_args(&[(0, INPUT_PLUMBER_BUS)])
        .await
        .map_err(|e| e.to_string())?;
    let bus = BusName::from_static_str(INPUT_PLUMBER_BUS).unwrap();
    loop {
        let owner = match tokio::time::timeout(TIMEOUT, dbus.get_name_owner(bus.clone())).await {
            Ok(Ok(owner)) => owner.to_string(),
            Ok(Err(zbus::fdo::Error::NameHasNoOwner(_))) => {
                tx.send_replace(Discovery::default());
                tokio::select! {
                    _ = tx.closed() => return Ok(()),
                    event = owners.next() => { if event.is_none() { return Err("Owner subscription ended".into()); } }
                }
                continue;
            }
            Ok(Err(error)) => return Err(error.to_string()),
            Err(_) => return Err("LED discovery timed out".into()),
        };
        // Pin this generation to the unique owner. A fast daemon restart must
        // not leave an old resource addressing the new service at the same path.
        let proxy = ObjectManagerProxy::builder(connection)
            .destination(owner.clone())
            .map_err(|e| e.to_string())?
            .path(INPUT_PLUMBER_PATH)
            .map_err(|e| e.to_string())?
            .build()
            .await
            .map_err(|e| e.to_string())?;
        let mut added = proxy
            .receive_interfaces_added()
            .await
            .map_err(|e| e.to_string())?;
        let mut removed = proxy
            .receive_interfaces_removed()
            .await
            .map_err(|e| e.to_string())?;
        let objects = tokio::time::timeout(TIMEOUT, proxy.get_managed_objects())
            .await
            .map_err(|_| "LED discovery timed out")?
            .map_err(|e| e.to_string())?;
        let paths = objects
            .into_iter()
            .filter(|(_, interfaces)| interfaces.keys().any(|name| name.as_str() == LED_INTERFACE))
            .map(|(path, _)| path.to_string())
            .collect();
        let mut discovery = Discovery { owner, paths };
        tx.send_replace(discovery.clone());
        loop {
            tokio::select! {
                _ = tx.closed() => return Ok(()),
                event = owners.next() => {
                    if event.is_none() { return Err("Owner subscription ended".into()); }
                    // Re-read the owner rather than trusting queued transitions.
                    break;
                },
                event = added.next() => {
                    let Some(event) = event else { return Err("LED discovery subscription ended".into()); };
                    let args = event.args().map_err(|e| e.to_string())?;
                    if args.interfaces_and_properties.keys().any(|name| name.as_str() == LED_INTERFACE)
                        && discovery.paths.insert(args.object_path.to_string()) { tx.send_replace(discovery.clone()); }
                },
                event = removed.next() => {
                    let Some(event) = event else { return Err("LED discovery subscription ended".into()); };
                    let args = event.args().map_err(|e| e.to_string())?;
                    if args.interfaces.iter().any(|name| name.as_str() == LED_INTERFACE)
                        && discovery.paths.remove(args.object_path.as_str()) { tx.send_replace(discovery.clone()); }
                },
            }
        }
    }
}

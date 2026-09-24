//! Nonblocking Godot resource for a single persistent LED source.
use crate::dbus::inputplumber::led_device::{
    LedCapabilities, LedConfiguration, LedDeviceProxy, LedState,
};
use crate::{get_dbus_system, RUNTIME};
use futures_util::StreamExt;
use godot::prelude::*;
use std::time::Duration;
use tokio::{
    sync::{mpsc, watch},
    task::JoinHandle,
};

const TIMEOUT: Duration = Duration::from_secs(3);

#[derive(Clone, Debug, PartialEq)]
struct Snapshot {
    capabilities: LedCapabilities,
    state: LedState,
    connected: bool,
    error: String,
}
impl Default for Snapshot {
    fn default() -> Self {
        Self {
            capabilities: (0, String::new(), vec![], 2000, 30000),
            state: (
                0,
                ("off".into(), vec![255; 3], 30, 8000),
                "unavailable".into(),
                String::new(),
            ),
            connected: false,
            error: "Lighting controls are loading.".into(),
        }
    }
}
impl Snapshot {
    fn compatible(&self) -> bool {
        self.connected
            && self.capabilities.0 == 1
            && !self.capabilities.1.is_empty()
            && !self.capabilities.2.is_empty()
            && self.capabilities.3 >= 2000
            && self.capabilities.4 <= 30000
            && self.capabilities.3 <= self.capabilities.4
    }
    fn accepts(&self, config: &LedConfiguration) -> bool {
        self.compatible()
            && self.capabilities.2.contains(&config.0)
            && config.1.len() == 3
            && config.2 <= 100
            && (self.capabilities.3..=self.capabilities.4).contains(&config.3)
    }
}
#[derive(Clone, Debug, Default)]
struct ApplyResult {
    request: i64,
    success: bool,
    error: String,
}
struct Apply {
    request: i64,
    config: LedConfiguration,
}

/// Its properties are cached. All D-Bus work runs on the shared Tokio runtime;
/// closing an OGUI panel never stops or modifies InputPlumber's lighting worker.
#[derive(GodotClass)]
#[class(no_init, base=Resource)]
pub struct LedDevice {
    base: Base<Resource>,
    path: String,
    snapshot: Snapshot,
    updates: watch::Receiver<Snapshot>,
    results: watch::Receiver<ApplyResult>,
    requests: mpsc::Sender<Apply>,
    next_request: i64,
    last_result: i64,
    pending: Option<i64>,
    task: JoinHandle<()>,
}
#[godot_api]
impl LedDevice {
    #[signal]
    fn lighting_changed();
    #[signal]
    fn apply_finished(request: i64, success: bool, error: GString);

    pub fn new(path: String, owner: String) -> Gd<Self> {
        let (tx, updates) = watch::channel(Snapshot::default());
        let (result_tx, results) = watch::channel(ApplyResult::default());
        let (requests, rx) = mpsc::channel(8);
        let device_path = path.clone();
        let task = RUNTIME.spawn(async move {
            if let Err(error) = run(device_path, owner, tx.clone(), result_tx, rx).await {
                tx.send_modify(|snapshot| {
                    snapshot.connected = false;
                    snapshot.error = error;
                });
            }
        });
        Gd::from_init_fn(|base| Self {
            base,
            path,
            snapshot: Snapshot::default(),
            updates,
            results,
            requests,
            next_request: 0,
            last_result: 0,
            pending: None,
            task,
        })
    }
    #[func]
    pub fn get_dbus_path(&self) -> GString {
        self.path.as_str().into()
    }
    #[func]
    pub fn get_snapshot(&self) -> VarDictionary {
        let caps = &self.snapshot.capabilities;
        let state = &self.snapshot.state;
        let effects: PackedStringArray = caps.2.iter().map(GString::from).collect();
        let color: Array<i64> = state.1 .1.iter().map(|c| i64::from(*c)).collect();
        let config = vdict! { "effect": state.1.0.as_str(), "color": color, "brightness": i64::from(state.1.2), "cycle_period_ms": i64::from(state.1.3) };
        let error = if self.snapshot.error.is_empty() {
            state.3.as_str()
        } else {
            self.snapshot.error.as_str()
        };
        vdict! { "available": self.snapshot.compatible(), "api_version": i64::from(caps.0),
        "persistent_id": caps.1.as_str(), "effects": effects,
        "cycle_min_ms": i64::from(caps.3), "cycle_max_ms": i64::from(caps.4),
        "config": config, "revision": state.0.to_string(), "status": state.2.as_str(), "error": error }
    }
    /// Returns a local request ID, or zero if unavailable/invalid/busy. The
    /// apply_finished signal distinguishes persistence acceptance from failure;
    /// lighting_changed/State report actual hardware application separately.
    #[func]
    pub fn apply_config(
        &mut self,
        effect: GString,
        color: PackedByteArray,
        brightness: i64,
        cycle_period_ms: i64,
    ) -> i64 {
        if !(0..=100).contains(&brightness) || !(2000..=30000).contains(&cycle_period_ms) {
            return 0;
        }
        let config = (
            effect.to_string(),
            color.to_vec(),
            brightness as u32,
            cycle_period_ms as u32,
        );
        if self.pending.is_some() || !self.snapshot.accepts(&config) {
            return 0;
        }
        let Some(request) = self.next_request.checked_add(1) else {
            return 0;
        };
        if self.requests.try_send(Apply { request, config }).is_err() {
            return 0;
        }
        self.next_request = request;
        self.pending = Some(request);
        request
    }
    pub fn process(&mut self) {
        // A closed watch channel may still contain an unread final failure.
        if self.updates.has_changed().unwrap_or(true) {
            let snapshot = self.updates.borrow_and_update().clone();
            if self.snapshot != snapshot {
                self.snapshot = snapshot;
                self.base_mut().emit_signal("lighting_changed", &[]);
            }
        }
        if self.results.has_changed().unwrap_or(true) {
            let result = self.results.borrow_and_update().clone();
            if result.request > self.last_result {
                self.last_result = result.request;
                if self.pending == Some(result.request) {
                    self.pending = None;
                }
                self.base_mut().emit_signal(
                    "apply_finished",
                    &[
                        result.request.to_variant(),
                        result.success.to_variant(),
                        result.error.to_variant(),
                    ],
                );
            }
        }
        if !self.snapshot.connected && self.task.is_finished() {
            if let Some(request) = self.pending.take() {
                self.base_mut().emit_signal(
                    "apply_finished",
                    &[
                        request.to_variant(),
                        false.to_variant(),
                        "Lighting connection ended; refresh state before retrying.".to_variant(),
                    ],
                );
            }
        }
    }

    pub fn disconnect_device(&mut self) {
        self.task.abort();
        self.snapshot.connected = false;
        self.snapshot.error = "Lighting device disconnected.".into();
        self.base_mut().emit_signal("lighting_changed", &[]);
        if let Some(request) = self.pending.take() {
            self.base_mut().emit_signal(
                "apply_finished",
                &[
                    request.to_variant(),
                    false.to_variant(),
                    "Device disconnected; refresh state before retrying.".to_variant(),
                ],
            );
        }
    }
}
impl Drop for LedDevice {
    fn drop(&mut self) {
        self.task.abort();
    }
}

async fn read_snapshot(proxy: &LedDeviceProxy<'_>) -> Result<Snapshot, String> {
    let result = tokio::time::timeout(TIMEOUT, async {
        // Read after SetConfig must not reuse a property value cached before
        // its notification arrived. Keep the subscription proxy separately.
        let fresh = LedDeviceProxy::builder(proxy.inner().connection())
            .destination(proxy.inner().destination().to_owned())?
            .path(proxy.inner().path().to_owned())?
            .cache_properties(zbus::proxy::CacheProperties::No)
            .build()
            .await?;
        let (caps, state) = tokio::join!(fresh.capabilities(), fresh.state());
        Ok::<_, zbus::Error>(Snapshot {
            capabilities: caps?,
            state: state?,
            connected: true,
            error: String::new(),
        })
    })
    .await
    .map_err(|_| "Lighting state request timed out")?
    .map_err(|e| format!("InputPlumber lighting controls are unavailable: {e}"))?;
    if result.capabilities.0 != 1 {
        return Err("This InputPlumber lighting API version is unsupported. Update OpenGamepadUI and InputPlumber together.".into());
    }
    if result.state.1 .1.len() != 3
        || result.state.1 .2 > 100
        || !(2000..=30000).contains(&result.state.1 .3)
    {
        return Err("InputPlumber returned invalid lighting settings.".into());
    }
    Ok(result)
}
async fn refresh(
    proxy: &LedDeviceProxy<'_>,
    snapshots: &watch::Sender<Snapshot>,
) -> Result<(), String> {
    match read_snapshot(proxy).await {
        Ok(snapshot) => {
            snapshots.send_replace(snapshot);
            Ok(())
        }
        Err(error) => {
            snapshots.send_modify(|snapshot| {
                snapshot.connected = false;
                snapshot.error = error.clone();
            });
            Err(error)
        }
    }
}

async fn run(
    path: String,
    owner: String,
    snapshots: watch::Sender<Snapshot>,
    results: watch::Sender<ApplyResult>,
    requests: mpsc::Receiver<Apply>,
) -> Result<(), String> {
    let connection = tokio::time::timeout(TIMEOUT, get_dbus_system())
        .await
        .map_err(|_| "Lighting connection timed out")?
        .map_err(|e| e.to_string())?;
    run_on_connection(connection, path, owner, snapshots, results, requests).await
}

async fn run_on_connection(
    connection: zbus::Connection,
    path: String,
    owner: String,
    snapshots: watch::Sender<Snapshot>,
    results: watch::Sender<ApplyResult>,
    mut requests: mpsc::Receiver<Apply>,
) -> Result<(), String> {
    let proxy = LedDeviceProxy::builder(&connection)
        .destination(owner)
        .map_err(|e| e.to_string())?
        .path(path)
        .map_err(|e| e.to_string())?
        .build()
        .await
        .map_err(|e| e.to_string())?;
    // Subscribe before fetching initial state; startup/hotplug changes cannot be missed.
    let mut states = proxy.receive_state_changed().await;
    let mut capabilities = proxy.receive_capabilities_changed().await;
    let _ = refresh(&proxy, &snapshots).await;
    let mut retry = tokio::time::interval(Duration::from_secs(5));
    retry.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);
    retry.reset();
    loop {
        tokio::select! {
            command = requests.recv() => {
                let Some(command) = command else { return Ok(()); };
                let response = tokio::time::timeout(TIMEOUT, proxy.set_config(command.config)).await;
                let outcome = match response {
                    Ok(Ok(_)) => match refresh(&proxy, &snapshots).await {
                        Ok(()) => Ok(()),
                        Err(error) => Err(format!("Settings were accepted, but state could not be refreshed: {error}")),
                    },
                    Ok(Err(error)) => Err(error.to_string()),
                    Err(_) => Err("Lighting request timed out; refresh state before retrying.".into()),
                };
                results.send_replace(ApplyResult { request: command.request, success: outcome.is_ok(), error: outcome.err().unwrap_or_default() });
            },
            _ = retry.tick(), if !snapshots.borrow().connected => {
                let _ = refresh(&proxy, &snapshots).await;
            },
            event = states.next() => {
                if event.is_none() { return Err("Lighting state subscription ended.".into()); }
                let _ = refresh(&proxy, &snapshots).await;
            },
            event = capabilities.next() => {
                if event.is_none() { return Err("Lighting capabilities subscription ended.".into()); }
                let _ = refresh(&proxy, &snapshots).await;
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn compatible_snapshot_requires_supported_version_and_complete_configuration() {
        let mut snapshot = Snapshot {
            connected: true,
            capabilities: (
                1,
                "ayaneo-3-joystick-rings".into(),
                vec!["off".into(), "solid".into()],
                2000,
                30000,
            ),
            ..Snapshot::default()
        };
        let config = ("solid".into(), vec![1, 2, 3], 30, 8000);
        assert!(snapshot.accepts(&config));
        assert!(!snapshot.accepts(&("cycle".into(), vec![1, 2, 3], 30, 8000)));
        assert!(!snapshot.accepts(&("solid".into(), vec![1, 2], 30, 8000)));
        assert!(!snapshot.accepts(&("solid".into(), vec![1, 2, 3], 101, 8000)));
        snapshot.capabilities.0 = 2;
        assert!(!snapshot.accepts(&config));
        snapshot.capabilities.0 = 1;
        snapshot.connected = false;
        assert!(!snapshot.accepts(&config));
    }
}

#[cfg(test)]
#[path = "led_device_test.rs"]
mod wire;

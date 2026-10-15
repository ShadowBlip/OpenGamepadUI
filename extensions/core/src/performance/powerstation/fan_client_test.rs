use super::*;
use crate::performance::powerstation::fan_settings::FanSettings;
use std::{
    io::{BufRead, BufReader},
    process::{Child, Command, Stdio},
    sync::{Arc, Mutex},
};
const FAN: &str = "/org/shadowblip/Performance/Fan/Fan0";
const SENSOR: &str = "/org/shadowblip/Performance/Fan/Fan0/Sensor0";
const ROOT: &str = "/org/shadowblip/Performance/Fan";
const INVOCATION: &str = "11111111111111111111111111111111";
struct Bus {
    child: Child,
    address: String,
}
impl Bus {
    fn new() -> Self {
        let mut child = Command::new("dbus-daemon")
            .args(["--session", "--nofork", "--print-address=1"])
            .stdout(Stdio::piped())
            .spawn()
            .unwrap();
        let mut address = String::new();
        BufReader::new(child.stdout.take().unwrap())
            .read_line(&mut address)
            .unwrap();
        Self {
            child,
            address: address.trim().into(),
        }
    }
    async fn connection(&self) -> Connection {
        zbus::connection::Builder::address(self.address.as_str())
            .unwrap()
            .build()
            .await
            .unwrap()
    }
}
impl Drop for Bus {
    fn drop(&mut self) {
        let _ = self.child.kill();
        let _ = self.child.wait();
    }
}
#[derive(Default)]
struct State {
    profile: String,
    calls: Vec<String>,
    eligible: bool,
    denied: bool,
}
struct Root {
    state: Arc<Mutex<State>>,
    version: u32,
}
#[zbus::interface(name = "org.shadowblip.Fan")]
impl Root {
    fn enumerate_fans(&self) -> Vec<zbus::zvariant::OwnedObjectPath> {
        vec![FAN.try_into().unwrap()]
    }
    fn enumerate_sensors(&self) -> Vec<zbus::zvariant::OwnedObjectPath> {
        vec![SENSOR.try_into().unwrap()]
    }
    #[zbus(property)]
    fn api_version(&self) -> u32 {
        self.version
    }
    #[zbus(property)]
    fn current_profile_name(&self) -> String {
        self.state.lock().unwrap().profile.clone()
    }
    #[zbus(property)]
    fn current_profile_path(&self) -> String {
        String::new()
    }
    fn get_startup_status(&self) -> (String, String, bool) {
        (
            std::fs::read_to_string("/proc/sys/kernel/random/boot_id")
                .unwrap()
                .trim()
                .into(),
            INVOCATION.into(),
            self.state.lock().unwrap().eligible,
        )
    }
    fn load_profile_json(&self, json: &str) -> zbus::fdo::Result<()> {
        self.load(json, false)
    }
    fn load_profile(&self, file: &str) -> zbus::fdo::Result<()> {
        self.load(file, false)
    }
    fn load_startup_profile_json(
        &self,
        _boot: &str,
        invocation: &str,
        json: &str,
    ) -> zbus::fdo::Result<()> {
        if invocation != INVOCATION {
            return Err(zbus::fdo::Error::Failed("Wrong invocation".into()));
        }
        self.load(json, true)
    }
    fn load_startup_profile(
        &self,
        _boot: &str,
        invocation: &str,
        file: &str,
    ) -> zbus::fdo::Result<()> {
        self.load_startup_profile_json(_boot, invocation, file)
    }
}
impl Root {
    fn load(&self, value: &str, startup: bool) -> zbus::fdo::Result<()> {
        let mut state = self.state.lock().unwrap();
        if state.denied || (startup && !state.eligible) {
            return Err(zbus::fdo::Error::Failed("Fan request rejected".into()));
        }
        state.calls.push(value.into());
        state.profile = "Confirmed".into();
        state.eligible = false;
        Ok(())
    }
}
struct Device;
#[zbus::interface(name = "org.shadowblip.Fan.Device")]
impl Device {
    #[zbus(property)]
    fn id(&self) -> &str {
        "test/fan"
    }
    #[zbus(property)]
    fn name(&self) -> &str {
        "Test fan"
    }
    #[zbus(property)]
    fn mode(&self) -> &str {
        "automatic"
    }
    #[zbus(property)]
    fn available_modes(&self) -> Vec<&str> {
        vec!["automatic", "manual", "software_curve", "firmware_curve"]
    }
    #[zbus(property)]
    fn percent(&self) -> u8 {
        0
    }
    #[zbus(property)]
    fn percent_valid(&self) -> bool {
        false
    }
    #[zbus(property)]
    fn fault(&self) -> &str {
        ""
    }
}
struct Sensor;
#[zbus::interface(name = "org.shadowblip.Fan.Sensor")]
impl Sensor {
    #[zbus(property)]
    fn id(&self) -> &str {
        "test/fan/cpu"
    }
    #[zbus(property)]
    fn name(&self) -> &str {
        "CPU"
    }
    #[zbus(property)]
    fn temperature_c(&self) -> f64 {
        50.0
    }
    #[zbus(property)]
    fn telemetry_valid(&self) -> bool {
        true
    }
}
async fn server(bus: &Bus, state: Arc<Mutex<State>>, version: u32) -> Connection {
    zbus::connection::Builder::address(bus.address.as_str())
        .unwrap()
        .serve_at(ROOT, Root { state, version })
        .unwrap()
        .serve_at(FAN, Device)
        .unwrap()
        .serve_at(SENSOR, Sensor)
        .unwrap()
        .name(POWERSTATION_BUS)
        .unwrap()
        .build()
        .await
        .unwrap()
}
fn selection() -> Value {
    json!({"kind":"json", "profile":{"name":"Test", "fans":[{"fan":"test/fan", "mode":"manual", "percent":60}]}})
}
#[tokio::test]
async fn snapshot_exposes_v2_sensors_capabilities_and_explicit_percent_validity() {
    let bus = Bus::new();
    let state = Arc::new(Mutex::new(State {
        eligible: true,
        ..Default::default()
    }));
    let _server = server(&bus, state.clone(), 2).await;
    let connection = bus.connection().await;
    let first = snapshot(&connection).await.unwrap();
    assert_eq!(first["api_version"], 2);
    assert_eq!(first["fans"][0]["percent_valid"], false);
    assert_eq!(first["sensors"][0]["telemetry_valid"], true);
    assert_eq!(
        first["fans"][0]["available_modes"]
            .as_array()
            .unwrap()
            .len(),
        4
    );
    assert!(first["fans"][0].get("rpm").is_none());
    state.lock().unwrap().profile = "External".into();
    assert_eq!(
        snapshot(&connection).await.unwrap()["profile_name"],
        "External",
        "no stale property cache"
    );
    assert!(state.lock().unwrap().calls.is_empty());
}
#[tokio::test]
async fn old_and_future_api_versions_never_receive_writes() {
    for version in [1, 3] {
        let bus = Bus::new();
        let state = Arc::new(Mutex::new(State::default()));
        let service = server(&bus, state.clone(), version).await;
        let connection = bus.connection().await;
        assert_eq!(snapshot(&connection).await.unwrap()["available"], false);
        assert!(apply(
            &connection,
            service.unique_name().unwrap().as_str(),
            &selection(),
            None
        )
        .await
        .is_err());
        assert!(state.lock().unwrap().calls.is_empty());
    }
}
#[tokio::test]
async fn explicit_profiles_report_errors_and_never_retarget_a_replacement_owner() {
    let bus = Bus::new();
    let state = Arc::new(Mutex::new(State::default()));
    let first = server(&bus, state.clone(), 2).await;
    let connection = bus.connection().await;
    let owner = first.unique_name().unwrap().to_string();
    apply(&connection, &owner, &selection(), None)
        .await
        .unwrap();
    assert_eq!(state.lock().unwrap().calls.len(), 1);
    state.lock().unwrap().denied = true;
    assert!(apply(&connection, &owner, &selection(), None)
        .await
        .unwrap_err()
        .contains("rejected"));
    first.release_name(POWERSTATION_BUS).await.unwrap();
    let replacement_state = Arc::new(Mutex::new(State::default()));
    let _replacement = server(&bus, replacement_state.clone(), 2).await;
    assert!(apply(&connection, &owner, &selection(), None)
        .await
        .is_err());
    assert!(replacement_state.lock().unwrap().calls.is_empty());
    assert_eq!(state.lock().unwrap().calls.len(), 1);
}
#[tokio::test]
async fn saved_restore_consumes_attempt_before_a_denied_request_and_cannot_replay() {
    let bus = Bus::new();
    let state = Arc::new(Mutex::new(State {
        eligible: true,
        denied: true,
        ..Default::default()
    }));
    let service = server(&bus, state.clone(), 2).await;
    let connection = bus.connection().await;
    let directory =
        std::env::temp_dir().join(format!("ogui-fan-restore-denied-{}", std::process::id()));
    let settings = FanSettings::new(directory.clone());
    settings.save(&selection()).unwrap();
    assert!(restore(&connection, &settings).await.is_err());
    state.lock().unwrap().denied = false;
    assert!(restore(&connection, &settings)
        .await
        .unwrap_err()
        .contains("already attempted"));
    assert!(state.lock().unwrap().calls.is_empty());
    service.release_name(POWERSTATION_BUS).await.unwrap();
    fs_cleanup(&directory);
}
#[tokio::test]
async fn successful_restore_is_once_per_boot_and_later_invocation_stays_automatic() {
    let bus = Bus::new();
    let state = Arc::new(Mutex::new(State {
        eligible: true,
        ..Default::default()
    }));
    let service = server(&bus, state.clone(), 2).await;
    let connection = bus.connection().await;
    let directory =
        std::env::temp_dir().join(format!("ogui-fan-restore-success-{}", std::process::id()));
    let settings = FanSettings::new(directory.clone());
    settings
        .save(&json!({"kind":"file", "file":"quiet.yaml"}))
        .unwrap();
    restore(&connection, &settings).await.unwrap();
    assert_eq!(state.lock().unwrap().calls, vec!["quiet.yaml"]);
    assert!(restore(&connection, &settings).await.is_err());
    service.release_name(POWERSTATION_BUS).await.unwrap();
    let later = Arc::new(Mutex::new(State::default()));
    let _replacement = server(&bus, later.clone(), 2).await;
    assert!(restore(&connection, &settings).await.is_err());
    assert!(later.lock().unwrap().calls.is_empty());
    fs_cleanup(&directory);
}
fn fs_cleanup(path: &std::path::Path) {
    std::fs::remove_dir_all(path).unwrap();
}

use super::*;
#[cfg(test)]
mod wire_tests {
    use super::*;
    use crate::input::inputplumber::{led_discovery, INPUT_PLUMBER_BUS, INPUT_PLUMBER_PATH};
    use std::{
        io::{BufRead, BufReader},
        process::{Child, Command, Stdio},
        sync::{Arc, Mutex},
    };

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
                .expect("private dbus-daemon is required");
            let mut address = String::new();
            BufReader::new(child.stdout.take().unwrap())
                .read_line(&mut address)
                .unwrap();
            Self {
                child,
                address: address.trim().into(),
            }
        }
        async fn connection(&self) -> zbus::Connection {
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

    struct FakeLed {
        state: Arc<Mutex<LedState>>,
        version: u32,
    }
    #[zbus::interface(name = "org.shadowblip.Input.Source.LEDDevice")]
    impl FakeLed {
        #[zbus(property)]
        fn capabilities(&self) -> LedCapabilities {
            (
                self.version,
                "test-rings".into(),
                vec!["off".into(), "solid".into(), "cycle".into()],
                2000,
                30000,
            )
        }
        #[zbus(property)]
        fn state(&self) -> zbus::fdo::Result<LedState> {
            let state = self.state.lock().unwrap();
            if state.3 == "read-error" {
                return Err(zbus::fdo::Error::Failed(
                    "Transient state read failure".into(),
                ));
            }
            Ok(state.clone())
        }
        fn set_config(&self, config: LedConfiguration) -> zbus::fdo::Result<u64> {
            if config.2 == 13 {
                return Err(zbus::fdo::Error::AccessDenied(
                    "Test authorization denied".into(),
                ));
            }
            let mut state = self.state.lock().unwrap();
            state.0 += 1;
            state.1 = config;
            state.2 = "pending".into();
            if state.1 .2 == 12 {
                state.3 = "read-error".into();
            }
            Ok(state.0)
        }
    }
    const PATH: &str = "/org/shadowblip/InputPlumber/devices/source/vendor_rings";
    fn state() -> Arc<Mutex<LedState>> {
        Arc::new(Mutex::new((
            0,
            ("off".into(), vec![255; 3], 30, 8000),
            "applied".into(),
            String::new(),
        )))
    }
    async fn server(bus: &Bus, state: Arc<Mutex<LedState>>, version: u32) -> zbus::Connection {
        zbus::connection::Builder::address(bus.address.as_str())
            .unwrap()
            .serve_at(INPUT_PLUMBER_PATH, zbus::fdo::ObjectManager)
            .unwrap()
            .serve_at(PATH, FakeLed { state, version })
            .unwrap()
            .name(INPUT_PLUMBER_BUS)
            .unwrap()
            .build()
            .await
            .unwrap()
    }
    async fn wait_discovery(
        rx: &mut watch::Receiver<led_discovery::Discovery>,
        owner: &str,
        present: bool,
    ) {
        tokio::time::timeout(
            Duration::from_secs(4),
            rx.wait_for(|state| state.owner == owner && state.paths.contains(PATH) == present),
        )
        .await
        .unwrap()
        .unwrap();
    }

    #[tokio::test]
    async fn discovery_follows_interface_hotplug_and_fast_unique_owner_replacement() {
        let bus = Bus::new();
        let connection = bus.connection().await;
        let (tx, mut updates) = watch::channel(led_discovery::Discovery::default());
        let task = tokio::spawn(async move { led_discovery::run(&connection, &tx).await });
        let first = server(&bus, state(), 1).await;
        let first_owner = first.unique_name().unwrap().to_string();
        wait_discovery(&mut updates, &first_owner, true).await;
        first
            .object_server()
            .remove::<FakeLed, _>(PATH)
            .await
            .unwrap();
        wait_discovery(&mut updates, &first_owner, false).await;
        first
            .object_server()
            .at(
                PATH,
                FakeLed {
                    state: state(),
                    version: 1,
                },
            )
            .await
            .unwrap();
        wait_discovery(&mut updates, &first_owner, true).await;
        first.release_name(INPUT_PLUMBER_BUS).await.unwrap();
        let second = server(&bus, state(), 1).await;
        let second_owner = second.unique_name().unwrap().to_string();
        assert_ne!(first_owner, second_owner);
        wait_discovery(&mut updates, &second_owner, true).await;
        task.abort();
        let _ = task.await;
    }

    #[tokio::test]
    async fn worker_uses_real_tuples_fresh_reads_notifications_and_authorization_errors() {
        let bus = Bus::new();
        let hardware = state();
        let server = server(&bus, hardware.clone(), 1).await;
        let owner = server.unique_name().unwrap().to_string();
        let client = bus.connection().await;
        let (tx, mut updates) = watch::channel(Snapshot::default());
        let (results_tx, mut results) = watch::channel(ApplyResult::default());
        let (requests, rx) = mpsc::channel(8);
        let task = tokio::spawn(run_on_connection(
            client,
            PATH.into(),
            owner,
            tx,
            results_tx,
            rx,
        ));
        tokio::time::timeout(TIMEOUT, updates.wait_for(|s| s.connected))
            .await
            .unwrap()
            .unwrap();
        let config = ("solid".into(), vec![12, 34, 56], 47, 8000);
        requests
            .send(Apply {
                request: 1,
                config: config.clone(),
            })
            .await
            .unwrap();
        tokio::time::timeout(TIMEOUT, results.wait_for(|r| r.request == 1))
            .await
            .unwrap()
            .unwrap();
        assert!(results.borrow().success);
        // Fake setter deliberately sends no notification. The reply must use a
        // fresh Get rather than the subscription proxy's old property cache.
        assert_eq!(updates.borrow().state.1, config);
        assert_eq!(updates.borrow().state.2, "pending");
        hardware.lock().unwrap().2 = "failed".into();
        hardware.lock().unwrap().3 = "Device write failed".into();
        let iface = server
            .object_server()
            .interface::<_, FakeLed>(PATH)
            .await
            .unwrap();
        iface
            .get()
            .await
            .state_changed(iface.signal_emitter())
            .await
            .unwrap();
        tokio::time::timeout(TIMEOUT, updates.wait_for(|s| s.state.2 == "failed"))
            .await
            .unwrap()
            .unwrap();
        requests
            .send(Apply {
                request: 2,
                config: ("off".into(), vec![1, 2, 3], 13, 8000),
            })
            .await
            .unwrap();
        tokio::time::timeout(TIMEOUT, results.wait_for(|r| r.request == 2))
            .await
            .unwrap()
            .unwrap();
        assert!(!results.borrow().success);
        assert!(results.borrow().error.contains("denied"));
        assert_eq!(hardware.lock().unwrap().1, config);
        let recovered_config = ("solid".into(), vec![4, 5, 6], 12, 8000);
        requests
            .send(Apply {
                request: 3,
                config: recovered_config.clone(),
            })
            .await
            .unwrap();
        tokio::time::timeout(TIMEOUT, results.wait_for(|r| r.request == 3))
            .await
            .unwrap()
            .unwrap();
        assert!(!results.borrow().success);
        assert!(results.borrow().error.contains("accepted"));
        assert!(!updates.borrow().connected);
        hardware.lock().unwrap().3.clear();
        tokio::time::timeout(Duration::from_secs(8), updates.wait_for(|s| s.connected))
            .await
            .unwrap()
            .unwrap();
        assert_eq!(updates.borrow().state.1, recovered_config);
        drop(requests);
        tokio::time::timeout(TIMEOUT, task)
            .await
            .unwrap()
            .unwrap()
            .unwrap();
        assert_eq!(
            hardware.lock().unwrap().1,
            recovered_config,
            "Client exit must not turn lighting off"
        );
    }

    #[tokio::test]
    async fn future_protocol_is_unavailable_instead_of_writable() {
        let bus = Bus::new();
        let server = server(&bus, state(), 2).await;
        let client = bus.connection().await;
        let proxy = LedDeviceProxy::builder(&client)
            .destination(server.unique_name().unwrap().clone())
            .unwrap()
            .path(PATH)
            .unwrap()
            .build()
            .await
            .unwrap();
        assert!(read_snapshot(&proxy)
            .await
            .unwrap_err()
            .contains("unsupported"));
    }
}

#[test]
fn led_fixed_cycle_capability_preserves_saved_period_and_rejects_malformed_bounds() {
    let mut snapshot = Snapshot {
        connected: true,
        capabilities: (
            1,
            "native-rings".into(),
            vec![
                "off".into(),
                "solid".into(),
                "breathing".into(),
                "cycle".into(),
            ],
            0,
            0,
        ),
        ..Snapshot::default()
    };
    assert!(snapshot.compatible());
    for effect in ["off", "solid", "breathing", "cycle"] {
        for period in [2000, 17000, 30000] {
            assert!(snapshot.accepts(&(effect.into(), vec![19, 61, 127], 60, period)));
        }
    }
    for period in [0, 1999, 30001, u32::MAX] {
        assert!(!snapshot.accepts(&("cycle".into(), vec![255; 3], 60, period)));
    }
    for bounds in [(0, 2000), (2000, 0), (1, 1), (30000, 2000), (2000, 30001)] {
        snapshot.capabilities.3 = bounds.0;
        snapshot.capabilities.4 = bounds.1;
        assert!(!snapshot.compatible());
        assert!(!snapshot.accepts(&("cycle".into(), vec![255; 3], 60, 8000)));
    }
}

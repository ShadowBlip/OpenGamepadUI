extends GutTest

var bluetooth := load("res://core/systems/bluetooth/bluetooth_manager.tres") as BluetoothManager


func before_all() -> void:
	if not bluetooth.supports_bluetooth():
		@warning_ignore("unsafe_method_access")
		gut.p("Bluetooth is not supported")
		return


func test_get_adapter() -> void:
	if not bluetooth.supports_bluetooth():
		pass_test("Bluetooth not supported, skipping")
		return
	var adapter := bluetooth.get_adapter()
	if not adapter:
		pass_test("No bluetooth adapter found, skipping")
	pass_test("Skipping")


func test_discovery() -> void:
	if not bluetooth.supports_bluetooth():
		pass_test("Bluetooth not supported, skipping")
		return
	var adapter := bluetooth.get_adapter()
	if not adapter:
		pass_test("No bluetooth adapter found, skipping")

	adapter.start_discovery()
	await wait_seconds(3, "waiting for discovery")
	var discovered := bluetooth.get_discovered_devices()
	for device in discovered:
		gut.p("discovered device: " + device.address)
	adapter.stop_discovery()
	pass_test("Skipping")

extends GutTest

var network_manager := load("res://core/systems/network/network_manager.tres") as NetworkManagerInstance

const SSID := "SomeSSID"
const PSK := "SomePassword"


func before_all() -> void:
	if not network_manager.is_running():
		@warning_ignore("unsafe_method_access")
		gut.p("Networking is not supported")
		return


func test_connect() -> void:
	if not network_manager.is_running():
		pass_test("Networking not supported, skipping")
		return
	var devices := network_manager.get_devices()
	if devices.is_empty():
		pass_test("No network adapters found, skipping")
		return
	var wireless_devices := devices.filter(func(device: NetworkDevice): return device.wireless != null)
	if wireless_devices.is_empty():
		pass_test("No wireless adapters found, skipping")
		return
	gut.p("Found wireless devices: " + str(wireless_devices))
	var device := wireless_devices[0] as NetworkDevice
	var access_point: NetworkAccessPoint
	for ap in device.wireless.access_points:
		if ap.ssid != SSID:
			continue
		access_point = ap
		break
	
	if not access_point:
		pass_test("No valid wireless networks found, skipping")
		return
	
	var connection := access_point.connect(device, PSK)
	
	for i in range(50):
		var state := connection.state
		gut.p("Device state: " + str(device.state))
		gut.p("Connection state: " + str(state))
		match device.state:
			device.NM_DEVICE_STATE_CONFIG:
				gut.p("Connecting...")
			device.NM_DEVICE_STATE_NEED_AUTH:
				gut.p("Authentication required")
				break
			device.NM_DEVICE_STATE_ACTIVATED:
				gut.p("Successfully connected!")
				break
			device.NM_DEVICE_STATE_IP_CONFIG:
				gut.p("Aquiring IP address...")
			device.NM_DEVICE_STATE_DEACTIVATING:
				gut.p("Deactivation connection...")
		
		await wait_seconds(1, "waiting for connection")
	
	pass_test("Skipping")


func test_get_devices() -> void:
	if not network_manager.is_running():
		pass_test("Networking not supported, skipping")
		return
	var devices := network_manager.get_devices()
	if devices.is_empty():
		pass_test("No network adapters found, skipping")
	for device in devices:
		@warning_ignore("unsafe_method_access")
		gut.p("discovered device: " + device.dbus_path)
		
		if device.ip4_config:
			gut.p("  found address: " + str(device.ip4_config.addresses))
		
		if device.device_type == device.NM_DEVICE_TYPE_ETHERNET:
			assert_null(device.wireless)
			@warning_ignore("unsafe_method_access")
			gut.p("  discovered ethernet device")
		if device.device_type == device.NM_DEVICE_TYPE_WIFI:
			assert_not_null(device.wireless)
			@warning_ignore("unsafe_method_access")
			gut.p("  discovered wireless device: " + device.wireless.dbus_path)
			if device.wireless.active_access_point:
				gut.p("  active access point: " + device.wireless.active_access_point.ssid)
			for ap in device.wireless.access_points:
				gut.p("  discovered access point: " + ap.ssid)
				gut.p("    strength: " + str(ap.strength))
				gut.p("    freq: " + str(ap.frequency))
				gut.p("    max bitrate: " + str(ap.max_bitrate))
	pass_test("Skipping")

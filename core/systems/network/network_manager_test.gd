extends Test

var network_manager := load("res://core/systems/network/network_manager.tres") as NetworkManager

func _ready() -> void:
	if not network_manager.supports_network():
		return

	var devices := network_manager.get_devices_by_type(NetworkManager.DEVICE_TYPE.WIFI)
	for device in devices:
		print(device.interface)
		if device is NetworkManager.WirelessDevice:
			print("Device is a wifi device")
			device.request_scan()
			for ap in device.get_all_access_points():
				print("Found AP: ", ap.ssid)

	#for ap in NetworkManager.get_access_points():
	#	logger.info(ap.ssid + " " + str(ap.strength))

	#for device in NetworkManager.get_devices():
	#	logger.info(device.device + " " + device.type + " " + device.state)

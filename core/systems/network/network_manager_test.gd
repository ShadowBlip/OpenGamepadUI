extends Test


func _ready() -> void:
	if not NetworkManager.supports_network():
		return
		
	for ap in NetworkManager.get_access_points():
		logger.info(ap.ssid + " " + str(ap.strength))

	for device in NetworkManager.get_devices():
		logger.info(device.device + " " + device.type + " " + device.state)

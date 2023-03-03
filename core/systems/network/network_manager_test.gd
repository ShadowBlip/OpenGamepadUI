extends Node


func _ready() -> void:
	for ap in NetworkManager.get_access_points():
		print(ap.ssid, " ", ap.strength)

	for device in NetworkManager.get_devices():
		print(device.device, " ", device.type, " ", device.state)

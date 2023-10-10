extends GutTest


func test_get_access_points() -> void:
	if not NetworkManager.supports_network():
		pass_test("Networking not supported, skipping")
		return

	for ap in NetworkManager.get_access_points():
		gut.p("Found AP: " + str(ap.ssid))

	for device in NetworkManager.get_devices():
		gut.p("Found device: " + device.device + " " + device.type + " " + device.state)
	pass_test("Skipping")

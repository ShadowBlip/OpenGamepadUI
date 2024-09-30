extends GutTest


func test_upower() -> void:
	var power_manager := PowerManager.new()
	power_manager.instance = load("res://core/systems/power/power_manager.tres")
	add_child_autoqfree(power_manager)
	
	if not power_manager.instance.is_running():
		gut.p("InputPlumber is not running. Skipping tests.")
		return

	# Get the display device
	var display_device := power_manager.instance.get_display_device()
	assert_eq(display_device.dbus_path, "/org/freedesktop/UPower/devices/DisplayDevice")
	gut.p("DBus Path: " + str(display_device.dbus_path))
	gut.p("Battery level: " + str(display_device.battery_level))
	gut.p("Icon name: " + str(display_device.icon_name))
	gut.p("Percentage: " + str(display_device.percentage))
	gut.p("State: " + str(display_device.state))

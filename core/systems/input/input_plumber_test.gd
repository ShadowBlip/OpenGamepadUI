extends GutTest


# Configure the given composite device to set intercept mode and print input
# events
func _watch_device(device: CompositeDevice) -> void:
	gut.p("  Found device " + str(device) + " at " + device.dbus_path)
	device.intercept_mode = InputPlumberInstance.INTERCEPT_MODE_ALL
	assert_eq(device.intercept_mode, InputPlumberInstance.INTERCEPT_MODE_ALL)
	var dbus_devices := device.dbus_devices
	if dbus_devices.is_empty():
		gut.p("  No dbus devices found for device")
		return
	var dbus_device := dbus_devices[0]
	gut.p("  Found DBus device: " + str(dbus_device) + " at " + dbus_device.dbus_path)
	var on_input_event := func(event: String, value: float):
		gut.p("[DBus Event] " + event + ": " + str(value))
	dbus_device.input_event.connect(on_input_event)


func test_inputplumber() -> void:
	var inputplumber := InputPlumber.new()
	inputplumber.instance = load("res://core/systems/input/input_plumber.tres")
	add_child_autoqfree(inputplumber)
	
	if not inputplumber.instance.is_running():
		pass_test("InputPlumber is not running. Skipping tests.")
		return

	# Set intercept mode
	gut.p("Setting intercept mode to ALL")
	inputplumber.instance.intercept_mode = InputPlumberInstance.INTERCEPT_MODE_ALL
	assert_eq(inputplumber.instance.intercept_mode, InputPlumberInstance.INTERCEPT_MODE_ALL)

	# Find all composite devices
	gut.p("Discovering all composite devices")
	var devices := inputplumber.instance.get_composite_devices()
	for device in devices:
		_watch_device(device)

	# Add listeners for any new devices
	inputplumber.instance.composite_device_added.connect(_watch_device)
	
	# Add listeners when devices are removed
	var on_device_removed := func(dbus_path: String):
		gut.p("Device was removed: " + dbus_path)
	inputplumber.instance.composite_device_removed.connect(on_device_removed)

	await wait_seconds(30, "Waiting 30s... Press buttons to test")

	inputplumber.instance.intercept_mode = InputPlumberInstance.INTERCEPT_MODE_NONE

extends Resource
class_name BluetoothManager

## Manage and interact with bluetooth devices
##
## Allows bluetooth management through bluez
## Reference: https://wiki.archlinux.org/title/bluetooth#Pairing
var thread := load("res://core/systems/threading/thread_pool.tres")

var logger := Log.get_logger("BluetoothManager", Log.LEVEL.DEBUG)

var discovered_devices: Array[BluetoothDevice]
var discovered_controllers: Array[ControllerDevice]
var current_controller: ControllerDevice
var started: bool = false
var bt_enabled: bool = true
var scanning: bool = false

signal devices_updated(devices: Array[BluetoothDevice])
signal controllers_updated(devices: Array[ControllerDevice])
signal enabled_updated(enabled: bool)
signal scan_completed()

## Bluetooth device
class BluetoothDevice:
	var name: String = ""
	var mac_address: String = ""
	var paired: bool = false
	var connected: bool = false
	var available: bool = false
	var signal_strength: float = -99.9
	var transmit_power: float = 0.0

class ControllerDevice:
	var name: String = ""
	var mac_address: String = ""
	var discoverable: bool = false
	var pairable: bool = false
	var powered: bool = false
	var discovering:  bool = false


func start(enabled_on_start: bool) -> bool:
	if started:
		logger.warn("BluetoothManager.start() called when it was already started.")
		return started

	logger.info("Starting BluetoothManager")
	thread.start()
	started = true
	bt_enabled = enabled_on_start
	get_controllers()
	return started


## Returns true if the system has bluetooth controls we support
func supports_bluetooth() -> bool:
	var code := OS.execute("which", ["bluetoothctl"])
	return code == 0


func set_enabled(enable: bool) -> void:
	bt_enabled = enable
	if enable == false:
		_do_enable("off")
		return
	_do_enable("on")


func _do_enable(status: String) -> void:
	var output:=  _do_bluetoothctl_cmd(["power", status])
	var exit_code: int = output[1]
	if exit_code != 0:
		logger.error("Failed to set controller to " + status + ". Error code:  " + str(exit_code))
	if status == "on":
		current_controller.powered = true
		_set_agent()
		return
	current_controller.powered = false


func _set_agent() -> void:
	var output:=  _do_bluetoothctl_cmd(["agent", "on"])
	var exit_code: int = output[1]
	if exit_code != 0:
		logger.error("Failed to set agent. Error code:  " + str(exit_code))


func select_controller(controller: ControllerDevice) -> void:
	if current_controller == controller:
		logger.debug(controller.mac_address + " already set as primary controller. Nothing to do.")
		return

#	# Turn off the current controller and forget all data.
#	if current_controller:
#		_do_enable("off")
#		discovered_devices = []

	# Switch controller
	current_controller = controller
	_do_controller_select(controller.mac_address)

#	# Set the enabled status according to the bt_enabled toggle
#	if bt_enabled:
#		_do_enable("on")
#	else:
#		_do_enable("off")

	# Get relevant new data.
	get_known_devices("Paired")
	get_known_devices("Connected")


func _do_controller_select(mac_address: String) -> void:
	logger.debug("Setting " + mac_address + " as primary controller.")
	var output:=  _do_bluetoothctl_cmd(["select", mac_address])
	var exit_code: int = output[1]
	if exit_code != 0:
		logger.error("Failed to set primary controller: " + mac_address + ". Error code:  " + str(exit_code))


## Probes for currently connected/piared devices
func get_known_devices(source: String) -> void:
	var output:=  _do_bluetoothctl_cmd(["devices", source])
	var exit_code: int = output[1]
	if exit_code != 0:
		logger.error("Failed to get " + source + " devices. Error code:  " + str(exit_code))
		return
	var devices: Array[BluetoothDevice] = []
	var device_list:= _get_devices_from_output(output[0])
	if device_list.size() == 0:
		logger.debug("Found nothing in a search of " + source + " devices.")
		return
	logger.debug("Found " + source + " Devices: " + str(device_list))
	for found_device in device_list:
		_update_device(found_device, source)
	logger.debug("Emit devices_updated")
	devices_updated.emit(discovered_devices)


func get_controllers() -> void:
	# Get the raw output
	var output:= _do_bluetoothctl_cmd(["list"])
	var exit_code: int = output[1]
	if exit_code != 0:
		logger.error("Failed to get controller devices. Error code:  " + str(exit_code))
		return

	# Parse the data for controllers
	var controller_list:= _get_controller_from_output(output[0])
	if controller_list.size() == 0:
		logger.error("Found nothing in a search of controller devices.")
		return
	logger.debug("Found controller devices: " + str(controller_list))

	# Select the first controller in the list if this is our first run.
	for found_device in controller_list:
		_update_controller(found_device)
	logger.debug("Emit controllers_updated")
	if not current_controller:
		select_controller(discovered_controllers[0])
	controllers_updated.emit(discovered_controllers)


## Starts or stops scan of bluetooth devices
func scan_devices() -> void:
	if scanning:
		logger.info("Scan already in progress. Ignoring request for scan.")
		return
	scanning = true
	logger.info("Start Scan Devices")
	var output: Array = await _do_async_btc(["scan", "on"], "5")
	var exit_code: int = output[1]
	if exit_code != 0:
		logger.error("Failed to scan devices. Error code:  " + str(exit_code))
		return
#	logger.debug("Got scan results: " + str(output))
	var devices: Array[BluetoothDevice] = []
	var device_list:= _get_devices_from_scan(output[0])
	if device_list.size() == 0:
		logger.info("Found nothing in a scan of devices.")
		return
#	logger.debug("Found Devices: " + str(device_list))
	for found_device in device_list:
		_update_device(found_device, "Scan")
	logger.info("Emit devices_updated")
	devices_updated.emit(discovered_devices)
	logger.info("Emit scan_completed")
	scanning = false
	scan_completed.emit()


func _update_device(listed_device: Dictionary, source: String) -> void:
	var index = _get_device_index(listed_device["mac_address"])
	var device: BluetoothDevice
	if index == -1:
#		logger.debug("Device is new. Adding to devices list")
		device = BluetoothDevice.new()
		device.mac_address = listed_device["mac_address"]
		if listed_device.has("name"):
			device.name = listed_device["name"]
		if source == "Connected":
			device.connected = true
			device.available = true
		elif source == "Paired":
			device.paired = true
		if listed_device.has("signal_strength"):
			device.signal_strength = listed_device["signal_strength"]
		if listed_device.has("transmit_power"):
			device.transmit_power = listed_device["transmit_power"]
		discovered_devices.append(device)
	else:
#		logger.debug("Device is old. Updating to " + source)
		if source == "Connected":
			discovered_devices[index].connected = true
		elif source == "Paired":
			discovered_devices[index].paired = true
		if listed_device.has("signal_strength"):
			discovered_devices[index].signal_strength = listed_device["signal_strength"]


func _update_controller(listed_device: Dictionary) -> void:
	var index = _get_controller_index(listed_device["mac_address"])
	var device: ControllerDevice
	if index == -1:
		logger.debug("Controller is new. Adding to controller list")
		device = ControllerDevice.new()
		device.mac_address = listed_device["mac_address"]
		device.name = listed_device["name"]
		device.powered = listed_device["powered"]
		device.discoverable = listed_device["discoverable"]
		device.pairable = listed_device["pairable"]
		discovered_controllers.append(device)


func _get_device_index(mac_address: String) -> int:
	var index:= -1
	if discovered_devices.size() == 0:
		return index
	var idx:= 0
	for device in discovered_devices:
		if device.mac_address == mac_address:
			index = idx
			break
		idx = idx +1
	return index


func _get_controller_index(mac_address: String) -> int:
	var index:= -1
	if discovered_controllers.size() == 0:
		return index
	var idx:= 0
	for device in discovered_controllers:
		if device.mac_address == mac_address:
			index = idx
			break
		idx = idx +1
	return index


func _get_devices_from_output(raw_output: String) -> Array:
	var devices:= []
	if raw_output == "":
#		logger.debug("No devices")
		return devices
	var clean_devices: String = raw_output.strip_edges()
	var split_devices:= clean_devices.split("\n")
	for device_string in split_devices:
		var split_device := device_string.split(" ")
		var device:= {
			"mac_address": "",
			"name": "",
		}
		if split_device[0].contains("Device"):
			device["mac_address"]= split_device[1]
			split_device.remove_at(1)
			split_device.remove_at(0)
			device["name"] = " ".join(split_device)
		logger.debug("Found devices: " + str(devices))
	return devices


func _get_controller_from_output(raw_output: String) -> Array:
	var devices:= []
	if raw_output == "":
#		logger.debug("No devices")
		return devices
	var clean_device: String = raw_output.strip_edges()
	var split_device:= clean_device.split("\n")
	var mac_address:= split_device[0].split(" ")[1]
#	logger.debug("mac_address: " + mac_address)
	var controller_data: Array = _do_bluetoothctl_cmd(["show", mac_address])[0].strip_edges().split("\n")
#	logger.debug("Controller_data: " + str(controller_data))
	var device:= {
		"mac_address": mac_address,
		"powered": false,
		"discoverable": false,
		"pairable": false
	}
	for data_string in controller_data:
#		logger.debug("Data string: " + data_string)
		var split_string: Array = data_string.split(" ")
		var match_string = split_string[0].strip_edges()
#		logger.debug("split_string[1]: " + split_string[1])
#		logger.debug("match_string: " + match_string)
		match match_string:
			"Name:":
				device["name"] = split_string[1]
			"Powered:":
				if split_string[1] == "yes":
					device["powered"] = true
			"Discoverable:":
				if split_string[1] == "yes":
					device["discoverable"] = true
			"Pairable:":
				if split_string[1] == "yes":
					device["pairable"] = true
	logger.debug("Found controller: " +str(devices))
	devices.append(device)
	return devices


func _get_devices_from_scan(raw_output: String) -> Array:
	var devices:= []
	if raw_output == "":
		return devices
	var clean_devices: String = raw_output.strip_edges()
	var split_devices:= clean_devices.split("\n")
	for device_string in split_devices:
		var split_device := device_string.split(" ")
		var device:= {
			"mac_address": "",
		}
		if not split_device[1].contains("Device"):
			continue
		device["mac_address"] = split_device[2]
		split_device.remove_at(2)
		split_device.remove_at(1)
		split_device.remove_at(0)
		if split_device[0] in ["Name:", "Alias:"]:
			split_device.remove_at(0)
#			logger.debug("Found device: " + " ".join(split_device))
			device["name"] = " ".join(split_device)
		elif split_device[0] == "TxPower:":
#			logger.debug("Found transmit power for device: " + split_device[1])
			device["transmit_power"] = float(split_device[1])
		elif split_device[0] == "RSSI:" :
#			logger.debug("Found signal strength for device: " + split_device[1])
			device["signal_strength"] = float(split_device[1])
		elif split_device[0] in ["UUIDs:", "ManufacturerData"]:
			continue
		else:
#			logger.debug("Found device: " + " ".join(split_device))
			device["name"] = " ".join(split_device)
		devices.append(device)
#		logger.debug("Found devices: " + str(devices))
	return devices


## Pair/Unpair/Connect/Disconnect to the BluetoothDevice associated with the given mac address
func _modify_device_connection(action: String, mac_address: String) -> bool:
	var args := [action, mac_address]
	var output:= await _do_async_btc(args)
	var exit_code: int = output[1]
	if exit_code != 0:
		logger.warn("Unable to " + action +" with: " + mac_address +" Error code: " + str(exit_code))
		return false
	logger.info(output[0])
	var result: Array = output[0].split("\n")
	var desired_result: bool = false
	var index := _get_device_index(mac_address)
	match action:
		"pair":
			if "Successful connected" in result:
				discovered_devices[index].paired = true
				desired_result = true
		"remove":
			if "Device has been removed" in result:
				discovered_devices[index].paired = false
				desired_result = true
		"connect":
			if "Connection successful" in result:
				discovered_devices[index].connected = true
				desired_result = true
		"disconnect":
			if "Successful disconnected" in result:
				discovered_devices[index].connected = false
				desired_result = true
	if desired_result:
		logger.info("Successfull " + action + " action for: " + mac_address)
		return true
	logger.info("Failed to " + action + " for: " + mac_address)
	return false


# Pass given arguments to bluetootchctl.
func _do_bluetoothctl_cmd(args: PackedStringArray, timeout: String = "0")-> Array:
	var command := "bluetoothctl"
	var cmd_args: PackedStringArray = ["--timeout", timeout]
	cmd_args.append_array(args)
	logger.debug("Command: " + command + " " + " ".join(cmd_args))
	var output := []
	var exit_code := OS.execute(command, cmd_args, output)
#	logger.debug("Output: " + str(output))
#	logger.debug("Exit code: " +str(exit_code))
	return [output[0], exit_code]


func _do_async_btc(args: PackedStringArray, timeout: String = "0")-> Array:
	return await thread.exec(_do_bluetoothctl_cmd.bind(args, timeout))

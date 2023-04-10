extends Resource
class_name BluetoothManager

## Manage and interact with bluetooth devices
##
## Allows bluetooth management through bluez
## Reference: https://wiki.archlinux.org/title/bluetooth#Pairing
var thread := load("res://core/systems/threading/thread_pool.tres")

var logger := Log.get_logger("BluetoothManager", Log.LEVEL.DEBUG)

var discovered_devices: Array[BluetoothDevice]
var started: bool = false

signal devices_updated(devices: Array[BluetoothDevice])


## Bluetooth device
class BluetoothDevice:
	var name: String = ""
	var mac_address: String = ""
	var paired: bool = false
	var connected: bool = false
	var available: bool = false
	var signal_strength: float = -99.9
	var transmit_power: float = 0.0


func start(toggle_on: bool) -> bool:
	if started:
		logger.warn("BluetoothManager.start() called when it was already started.")
		return started
	logger.info("Starting BluetoothManager")
	thread.start()
	started = true
	scan_devices("on")
	get_known_devices("Paired")
	get_known_devices("Connected")
	return started


func get_discovered_devices() -> Array[BluetoothDevice]:
	return discovered_devices


## Returns true if the system has bluetooth controls we support
func supports_bluetooth() -> bool:
	var code := OS.execute("which", ["bluetoothctl"])
	return code == 0


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
	devices_updated.emit(discovered_devices)


## Starts or stops scan of bluetooth devices
func scan_devices(status: String) -> void:
	logger.debug("Start Scan Devices")
	var output: Array = await _do_async_btc(["scan", status], "15")
	var exit_code: int = output[1]
	if exit_code != 0:
		logger.error("Failed to scan devices. Error code:  " + str(exit_code))
		return
#	logger.debug("Got scan results: " + str(output))
	var devices: Array[BluetoothDevice] = []
	var device_list:= _get_devices_from_scan(output[0])
	if device_list.size() == 0:
		logger.debug("Found nothing in a scan of devices.")
		return
#	logger.debug("Found Devices: " + str(device_list))
	for found_device in device_list:
		_update_device(found_device, "Scan")
	devices_updated.emit(discovered_devices)


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
			devices.append(device)
		logger.debug("Found devices: " + str(devices))
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

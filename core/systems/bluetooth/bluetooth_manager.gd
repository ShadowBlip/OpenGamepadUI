extends Resource
class_name BluetoothManager

## Manage and interact with bluetooth devices
##
## Allows bluetooth management through bluez
## Reference: https://wiki.archlinux.org/title/bluetooth#Pairing
const thread := preload("res://core/systems/threading/thread_pool.tres")

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


func start(toggle_on: bool) -> bool:
	if started:
		logger.warn("BluetoothManager.start() called when it was already started.")
		return started
	logger.info("Starting BluetoothManager")
	thread.start()
	_set_agent("on")
	get_devices("Paired")
	get_devices("Connected")
	scan_devices("on")
	started = true
	return started


func get_discovered_devices() -> Array[BluetoothDevice]:
	return discovered_devices


func _set_agent(status: String) -> void:
	var output: Array
	_do_bluetoothctl_cmd(["agent", status])
	logger.info("Agent status: " + str(output))


## Returns true if the system has bluetooth controls we support
func supports_bluetooth() -> bool:
	var code := OS.execute("which", ["bluetoothctl"])
	return code == 0


## Probes for currently connected devices
func get_devices(source: String) -> void:
	var output:=  _do_bluetoothctl_cmd(["devices", source])
	var exit_code: int = output[1]
	if exit_code != 0:
		logger.error("Failed to get " + source + " devices. Error code:  " + str(exit_code))
		return 
	var devices: Array[BluetoothDevice] = []
	var device_list:= _get_devices_from_output(output[0])
	if device_list.size() == 0:
		logger.info("Found nothing in a search of " + source + " devices.")
		return
	logger.info("Found " + source + " Devices: " + str(device_list))
	for found_device in device_list:
		_update_device(found_device, source)
	devices_updated.emit(discovered_devices)


## Starts or stops scan of bluetooth devices
func scan_devices(status: String) -> void:
	logger.debug("Start Scan Devices")
	var scan_results: Array = await thread.exec(_do_async_cmd.bind(["scan", status], "15"))
	logger.debug("Got scan results: " + str(scan_results))


func _update_device(listed_device: Array, source: String) -> void:
	var index = _get_device_index(listed_device)
	var device: BluetoothDevice
	if index == -1:
		logger.debug("Device is new. Adding to devices list")
		device = BluetoothDevice.new()
		device.mac_address = listed_device[0]
		device.name = listed_device[1]
		if source == "Connected":
			device.connected = true
			device.available = true
		elif source == "Paired":
			device.paired = true
		discovered_devices.append(device)
	else:
		logger.debug("Device is old. Updating to " + source)
		if source == "Connected":
			discovered_devices[index].connected = true
		elif source == "Paired":
			discovered_devices[index].paired = true


func _get_device_index(listed_device: Array) -> int:
	var index:= -1
	if discovered_devices.size() == 0:
		return index
	var idx:= 0
	for device in discovered_devices:
		if device.name == listed_device[1]:
			index = idx
			break
		idx = idx +1
	return index
		


func _get_devices_from_output(raw_output: Array) -> Array:
	var devices:= []
	if raw_output.size() == 0:
#		logger.debug("No devices")
		return devices
#	logger.debug(str(raw_output))
	for new_device in raw_output:
		var clean_device: String = new_device.strip_edges()
#		logger.debug("Clean Device: " +clean_device)
		var split_device:= clean_device.split(" ")
#		logger.debug("Split Device: " +str(split_device))
		var device:= []
		if split_device[0].contains("Device"):
			device.append(split_device[1])
			split_device.remove_at(1)
			split_device.remove_at(0)
			device.append(" ".join(split_device))
			devices.append(device)
#	logger.debug("Found devices: " + str(devices))
	return devices


## Pair to the BluetoothDevice associated with the given mac address
func pair_bluetooth_device(mac_address: String) -> bool:
	var args := ["pair", mac_address]
	var output:= _do_bluetoothctl_cmd(args, "5")
	if output[1] != "0":
		return false
	return true


# Pass given arguments to bluetootchctl.
func _do_bluetoothctl_cmd(args: PackedStringArray, timeout: String = "0")-> Array:
	var command = "bluetoothctl"
	var cmd_args: PackedStringArray = ["--timeout", timeout]
	cmd_args.append_array(args)
	var output = []
	var exit_code := OS.execute(command, cmd_args, output)
#	logger.debug("Command: " + command + " ".join(cmd_args))
#	logger.debug("Output: " + str(output))
#	logger.debug("Exit code: " +str(exit_code))
	return [output, exit_code]


func _do_async_cmd(args: PackedStringArray, timeout: String = "0")-> Array:
	_set_agent("on")
	return _do_bluetoothctl_cmd(args, timeout)

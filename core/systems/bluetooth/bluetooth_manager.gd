extends Resource
class_name BluetoothManager

## Manage and interact with bluetooth devices
##
## Allows bluetooth management through bluez
## Reference: https://wiki.archlinux.org/title/bluetooth#Pairing

var logger := Log.get_logger("BluetoothManager", Log.LEVEL.DEBUG)

var cmd_queue: Array[String] = []
var current_cmd := ""
var current_output: Array[String] = []
var discovered_devices: Array[BluetoothDevice]
var proc: InteractiveProcess
var state: STATE = STATE.READY

enum STATE {
	READY,
	PROMPT,
	EXECUTING,
}

signal command_finished(cmd: String, output: Array[String])
signal command_progressed(cmd: String, output: Array[String], finished: bool)
signal devices_updated(devices: Array[BluetoothDevice])
signal prompt_available


# Main thread signals
signal client_ready
var started: bool = false
var shared_thread: SharedThread


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
	shared_thread = SharedThread.new()
	shared_thread.name = "BluetoothManager"
	shared_thread.add_process(_thread_process)
	shared_thread.start()
	_set_agent("on")
	proc = InteractiveProcess.new("bluetoothctl")
	if proc.start() != OK:
		logger.error("Unable to spawn bluethoothctl")
		return started
	get_devices("Paired")
	get_devices("Connected")
#	scan_devices("on")
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
		logger.error("Failed to get devices with status: " + source)
		return 
	var devices: Array[BluetoothDevice] = []
	var device_list:= _get_devices_from_output(output[0])
	if device_list.size() == 0:
		logger.debug("No devices available that are " + source)
		return
	for found_device in device_list:
		_update_device(found_device, source)
	devices_updated.emit(discovered_devices)


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
		logger.debug("No devices")
		return devices
	logger.debug(str(raw_output))
	for new_device in raw_output:
		var clean_device: String = new_device.strip_edges()
		logger.debug("Clean Device: " +clean_device)
		var split_device:= clean_device.split(" ")
		logger.debug("Split Device: " +str(split_device))
		var device:= []
		if split_device[0].contains("Device"):
			device.append(split_device[1])
			split_device.remove_at(1)
			split_device.remove_at(0)
			device.append(" ".join(split_device))
			devices.append(device)
	logger.debug("Found devices: " + str(devices))
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
	logger.debug("Command: " + command + " ".join(cmd_args))
	logger.debug("Output: " + str(output))
	logger.debug("Exit code: " +str(exit_code))
	return [output, exit_code]

## Starts or stops scan of bluetooth devices
func scan_devices(status: String) -> void:
	_run_bluetoothctl_int(status)
	return


# Run bluetoothctl with the given arguments and an interactive shell.
func _run_bluetoothctl_int(status: String) -> void:
	_queue_cmd("bluetoothctl --agent=NoInputNoOutput")
	var cmd := "bluetoothctl scan " + status
	_queue_cmd(cmd)
	var on_progress := func(output: Array):
		logger.debug("on progress")
		for line in output:
			# Send the user's password if prompted
			if line.contains("Agent registered"):
				logger.debug("Agent registered!")
			if line.contains("[NEW]"):
				logger.debug("New device! " + line)
				continue
			if line.contains("[CHG]"):
				logger.debug("Change to device! " + line)
				continue
			if line.contains("[DEL]"):
				logger.debug("Device not present! " + line)
				continue

	# Pass the callback which will watch our command output
	await _follow_command(cmd, on_progress)


# Waits for the given command to produce some output and executes the given 
# callback with the output.
func _follow_command(cmd: String, callback: Callable) -> void:
	# Signal output: [cmd, output, finished]
	logger.debug("Start follow_command: " + cmd)
	var out: Array = [""]
	var finished = false
	while not finished:
		while out[0] != cmd:
			out = await command_progressed 
		var output := out[1] as Array
		finished = out[2]
		callback.call(output)
		# Clear the inner loop condition to fetch progress again
		out[0] = ""
	logger.debug("End follow_command: " + cmd)


func _queue_cmd(cmd: String) -> void:
	logger.debug("Queued command: " + cmd)
	cmd_queue.push_back(cmd)


func _thread_process(_delta: float) -> void:
	if not proc:
		return

	# Process our command queue
	_process_command_queue()

	# Read the output from the process
	var output := proc.read()

	# Return if there is no output from the process
	if output == "":
		return
	logger.debug("Start Process Thread. State: " + str(state))
	# Split the output into lines
	var lines := output.split("\n")
	current_output.append_array(lines)

	# Print the output of steamcmd, except during login for security reasons
	var out:= lines.duplicate()
	for line in lines:
		logger.debug("Thread Process out: " + line)
		
	command_finished.emit(current_cmd, out)
	current_cmd = ""
	current_output.clear()
	command_progressed.emit(current_cmd, out, true)
	logger.debug("End Process Thread. State: " + str(state))


# Processes commands in the queue source popping the first item in the queue and 
# setting our state to EXECUTING.
func _process_command_queue() -> void:
	if state != STATE.PROMPT or cmd_queue.size() == 0:
		return
	var cmd := cmd_queue.pop_front() as String
	state = STATE.EXECUTING
	current_cmd = cmd
	current_output.clear()
	proc.send(cmd)


func _exit_tree() -> void:
	if not proc:
		return
	proc.send("quit\n")
	proc.stop()

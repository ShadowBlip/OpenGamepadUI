extends NodeThread
class_name BluetoothManager

## Manage and interact with bluetooth devices
##
## Allows bluetooth management through bluez
## Reference: https://wiki.archlinux.org/title/bluetooth#Pairing

var logger := Log.get_logger("BluetoothManager", Log.LEVEL.DEBUG)

var cmd_queue: Array[String] = []
var current_cmd := ""
var current_output: Array[String] = []
var proc: InteractiveProcess
var state: STATE = STATE.READY

enum STATE {
	READY,
	PROMPT,
	EXECUTING,
}

signal command_finished(cmd: String, output: Array[String])
signal command_progressed(cmd: String, output: Array[String], finished: bool)
signal prompt_available

# Main thread signals
signal client_ready

## Bluetooth device
class BluetoothDevice:
	var name: String
	var mac_address: String
	var paired: bool


func _ready() -> void:
	thread_group = SharedThread.new()
	thread_group.name = "BluetoothManager"
	proc = InteractiveProcess.new("bluetoothctl")
	if proc.start() != OK:
		logger.error("Unable to spawn bluethoothctl")
		return


## Returns true if the system has bluetooth controls we support
static func supports_bluetooth() -> bool:
	var code := OS.execute("which", ["bluetoothctl"])
	return code == 0


## Returns a list of bluetooth devices
func scan_devices(status: String) -> void:
	_run_bluetoothctl_scan(status)


## Returns the currently paired devices
func get_conencted_devices() -> Array[BluetoothDevice]:
	var result: Array[BluetoothDevice] = []
	var output := _run_bluetoothctl_single(["devices", "Connected"])
	for line in output[0]:
		print(line)
		var device := BluetoothDevice.new()
		device.mac_address = ""
		device.name = ""
		result.append(device)

	return result


## Returns the currently paired devices
func get_paired_devices() -> Array[BluetoothDevice]:
	var result: Array[BluetoothDevice] = []
	var output := _run_bluetoothctl_single(["devices", "Paired"])
	for line in output[0]:
		print(line)
		var device := BluetoothDevice.new()
		device.mac_address = ""
		device.name = ""
		result.append(device)

	return result


## Pair to the given wifi access point
func pair_bluetooth_device(mac_address: String) -> int:
	var args := ["pair", mac_address]
	var result := _run_bluetoothctl_single(args)
	return result[1]


# Run bluetoothctl with the given arguments as a non-interactive shell.
func _run_bluetoothctl_single(args: PackedStringArray) -> Array:
	var output := []
	var exit_code := OS.execute("bluetoothctl", args, output)
	return [output[0], exit_code]


# Run bluetoothctl with the given arguments and an interactive shell.
func _run_bluetoothctl_scan(status: String) -> void:
	var cmd := "bluetoothctl scan " + status + "\n"
	_queue_cmd(cmd)
	var on_progress := func(output: Array):
		for line in output:
			# Send the user's password if prompted
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


func _queue_cmd(cmd: String) -> void:
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

	# Split the output into lines
	var lines := output.split("\n")
	current_output.append_array(lines)

	# Print the output of steamcmd, except during login for security reasons
	for line in lines:
		logger.debug("bluetoothctl: " + line)

	# Signal when command progress has been made 
	if current_cmd != "":
		var out := lines.duplicate()
		#emit_signal.call_deferred("command_progressed", current_cmd, out, false)
		command_progressed.emit(current_cmd, out, false)

#	# Signal that a steamcmd prompt is available
#	if lines[-1].begins_with("[bluetooth]#"):
#		if state == STATE.READY:
#			emit_signal.call_deferred("client_ready")
#		state = STATE.PROMPT
#		prompt_available.emit()
#
#		# If a command was executing, emit its output
#		if current_cmd == "":
#			return
#		var out := current_output.duplicate()
#		#emit_signal.call_deferred("command_progressed", current_cmd, [], true)
#		command_progressed.emit(current_cmd, [], true)
#		#emit_signal.call_deferred("command_finished", current_cmd, out)
#		command_finished.emit(current_cmd, out)
#		current_cmd = ""
#		current_output.clear()


# Processes commands in the queue by popping the first item in the queue and 
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


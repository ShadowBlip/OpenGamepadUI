extends Resource
class_name GamepadManager

## Manages virtual controllers
##
## The InputManager class is responsible for handling global input that should
## happen everywhere in the application. The input manager discovers gamepads
## and interepts their input so OpenGamepadUI can control what inputs should get
## passed on to the game and what only OpenGamepadUI should process. This works
## by grabbing exclusive access to the physical gamepads and creating a virtual
## gamepad that games can see.[br][br]
##
## This class should be loaded and managed by a single node in the scene tree.
## It requires to be initialized and passed input events:
##     [codeblock]
##     const InputManager := preload("res://core/global/input_manager.tres")
##
##     func _ready() -> void:
##         InputManager.init()
##
##     func _input(event: InputEvent) -> void:
##     	   if not InputManager.input(event):
##     	       return
##     	   get_viewport().set_input_as_handled()
##
##     func _exit_tree() -> void:
##     	   InputManager.exit()
##     [/codeblock]


var platform := load("res://core/global/platform.tres") as Platform
var device_hider := load("res://core/systems/input/device_hider.tres") as DeviceHider
var input_thread := load("res://core/systems/threading/input_thread.tres") as SharedThread
var in_game_state := preload("res://assets/state/states/in_game.tres") as State

var gamepads := GamepadArray.new()
var orphan_gamepads := GamepadArray.new()
#var gamepads: Array[Gamepad] = []
#var gamepad_phys_paths: Array[String] = []
#var gamepad_virt_path: Array[String] = []
#var managed_gamepads := {}  # {"/dev/input/event1": <ManagedGamepad>}
#var orphaned_gamepads := {} # {"event1" : <ManagedGamepad>}
#var virtual_gamepads := []  # ["/dev/input/event2"]
#var gamepad_mutex := Mutex.new()
var logger := Log.get_logger("GamepadManager", Log.LEVEL.INFO)


## Initializes the gamepad manager and starts the gamepad interecpt thread. 
func _init() -> void:
	in_game_state.state_entered.connect(_on_game_state_entered)
	in_game_state.state_exited.connect(_on_game_state_exited)
	in_game_state.state_removed.connect(_on_game_state_removed)

	# If we crashed, unhide any device events that were orphaned
	await device_hider.restore_all_hidden()

	# Discover any gamepads and grab exclusive access to them. Create a
	# duplicate virtual gamepad for each physical one.
	_on_gamepad_change(0, false)
	Input.joy_connection_changed.connect(_on_gamepad_change)

	# Create a thread to process gamepad inputs separately
	logger.debug("Starting gamepad input thread")
	input_thread.add_process(_process_input)
	input_thread.start()


## Returns a list of gamepad devices that are being exclusively managed.
func get_gamepad_paths() -> Array[String]:
	return gamepads.phys_paths()


## Sets the given gamepad profile on the given managed gamepad.
## E.g. set_gamepad_profile("/dev/input/event1", profile)
func set_gamepad_profile(device: String, profile: GamepadProfile) -> void:
	var gamepad := gamepads.get_by_phys(device)
	if not gamepad:
		logger.warn("Unable to set profile on non-managed device: " + device)
		return
	gamepad.set_profile(profile)


## Returns an array of input devices discovered under '/dev/input'
func discover_devices() -> Array[InputDevice]:
	var input_path := "/dev/input"
	var devices: Array[InputDevice] = []
	
	var files := DirAccess.get_files_at(input_path)
	for file in files:
		if not file.begins_with("event"):
			logger.debug("Ignoring device " + file)
			continue
		var path := "/".join([input_path, file])
		var dev := InputDevice.new()
		if dev.open(path) != OK:
			logger.debug("Unable to open event device: " + path)
			continue
		logger.debug("Added " + path + " to the list of discovered devices.")
		devices.append(dev)

	return devices

## Returns an array of discovered gamepad device paths.
## E.g. ["/dev/input/event1", "/dev/input/event2"]
func discover_gamepad_paths() -> PackedStringArray:
	var input_path := "/dev/input"
	var paths := PackedStringArray()
	
	var files := DirAccess.get_files_at(input_path)
	for file in files:
		if not file.begins_with("event"):
			continue
		var path := "/".join([input_path, file])
		var dev := InputDevice.new()
		if dev.open(path) != OK:
			logger.debug("Unable to open event device: " + path)
			continue
		if dev.has_event_code(InputDeviceEvent.EV_KEY, InputDeviceEvent.BTN_MODE):
			paths.append(path)
			continue
		if platform.platform and platform.platform is HandheldPlatform:
			var handheld_platform := platform.platform as HandheldPlatform
			if handheld_platform.is_handheld_keyboard(dev):
				paths.append(path)
			continue

	return paths


func exit() -> void:
	input_thread.stop()
	Input.joy_connection_changed.disconnect(_on_gamepad_change)
	for gamepad in gamepads.items():
		gamepad.close()
		
		if gamepad is ManagedGamepad:
			logger.debug("Cleaning up gamepad: " + gamepad.phys_path)
			gamepad.phys_device.grab(false)
			gamepad.virt_device.close()
			gamepad.phys_device.close()
			device_hider.restore_event_device(gamepad.phys_path)
		if gamepad is HandheldGamepad:
			logger.debug("Cleaning up handheld gamepad: " + gamepad.gamepad.phys_path)
			gamepad.gamepad.phys_device.grab(false)
			gamepad.gamepad.virt_device.close()
			gamepad.gamepad.phys_device.close()
			device_hider.restore_event_device(gamepad.gamepad.phys_path)
			
			gamepad.kb_device.grab(false)
			gamepad.kb_device.close()
			device_hider.restore_event_device(gamepad.kb_event_path)



## Sets the gamepad intercept mode
func _set_intercept(mode: ManagedGamepad.INTERCEPT_MODE) -> void:
	logger.debug("Setting gamepad intercept mode: " + str(mode))
	for gamepad in gamepads.items():
		gamepad.set_mode(mode)


## Runs evdev input processing in its own thread. We use mutexes to safely
## access variables from the main thread
func _process_input(_delta: float) -> void:
	# Process the input for all currently managed gamepads
	for gamepad in gamepads.items():
		gamepad.process_input()


## Triggers whenever we detect any gamepad connect/disconnect events
func _on_gamepad_change(device: int, connected: bool) -> void:
	logger.info("Gamepad was changed: " + Input.get_joy_name(device) + " connected: " + str(connected))
	
	logger.debug("Current Managed gamepads: " + str(gamepads.phys_paths()))
	
	# Discover any new gamepads
	var discovered_devices := discover_devices()
	var discovered_gamepads: Array[InputDevice] = []
	var discovered_keyboards: Array[InputDevice] = []
	var discovered_handheld: InputDevice
	for dev in discovered_devices:
		if platform.platform and platform.platform is HandheldPlatform:
			var handheld_platform := platform.platform as HandheldPlatform
			if handheld_platform.is_handheld_keyboard(dev):
				discovered_keyboards.append(dev)
			if handheld_platform.is_handheld_gamepad(dev):
				discovered_handheld = dev
			continue
		if dev.has_event_code(InputDeviceEvent.EV_KEY, InputDeviceEvent.BTN_MODE):
			discovered_gamepads.append(dev)
			continue

	# TODO: Handle handheld gamepad reconnecting

	# Setup any handheld gamepads if they are discovered and not yet configured
	if not gamepads.has_handheld() and discovered_handheld:
		var path := discovered_handheld.get_path()
		logger.info("A handheld gamepad was discovered at: " + path)
		# Hide the device from other processes
		logger.debug("Trying to hide handheld gamepad")
		var hidden_path := await device_hider.hide_event_device(path)
		if hidden_path == "":
			logger.warn("Unable to hide handheld gamepad: " + path)
			logger.warn("Opening the raw handheld gamepad instead")
			# Try to open the non-hidden device instead
			hidden_path = path

		# Create a new managed gamepad with physical/virtual gamepad pair
		logger.debug("Opening handheld gamepad at: " + hidden_path)
		var gamepad := HandheldGamepad.new()
		if gamepad.open(hidden_path) != OK:
			logger.error("Unable to create handheld gamepad for: " + hidden_path)
			if hidden_path != path:
				logger.debug("Restoring device back to its regular path")
				device_hider.restore_event_device(hidden_path)
		else:
			gamepad.setup(discovered_keyboards)
			gamepads.add(gamepad)

	# Remove all gamepads that no longer exist
	var hidden_devices := device_hider.get_hidden_devices()
	for gamepad in gamepads.items():
		# Do not delete physically unremovable gamepads that might virtually be disconnected
		if gamepad is HandheldGamepad:
			continue
		# Get the file name of the event device for the gamepad and see if it
		# exists in the hidden devices folder.
		if _get_event_from_phys(gamepad.get_phys_path()) in hidden_devices:
			continue
		# If the gamepad exists and the device wasn't hidden, do not remove it.
		if _get_event_from_phys(gamepad.get_phys_path()) in DirAccess.get_files_at("/dev/input"):
			continue

		logger.debug("Gamepad disconnected: " + gamepad.get_phys_path())
		gamepads.erase(gamepad)

	# Add any newly found gamepads
	for dev in discovered_gamepads:
		var path := dev.get_path()
		logger.debug("Considering gamepad: " + path)
		# Reject managed and virtual devices
		if gamepads.is_managed(path):
			logger.debug("Gamepad is already being managed: " + path)
			continue

		# See if we've identified the gamepad defined by the device platform.
		if dev.get_phys() == "":
			logger.debug("Device appears to be virtual, skipping " + path)
			continue
			
		# Hide the device from other processes
		var hidden_path := await device_hider.hide_event_device(path)
		if hidden_path == "":
			logger.warn("Unable to hide gamepad: " + path)
			logger.warn("Opening the raw gamepad instead")
			# Try to open the non-hidden device instead
			hidden_path = path

		# Create a new managed gamepad with physical/virtual gamepad pair
		var gamepad := ManagedGamepad.new()
		if gamepad.open(hidden_path) != OK:
			logger.error("Unable to create managed gamepad for: " + hidden_path)
			if hidden_path != path:
				device_hider.restore_event_device(hidden_path)
			continue

		gamepads.add(gamepad)
		logger.debug("Discovered gamepad at: " + gamepad.get_phys_path())
		logger.debug("Created virtual gamepad at: " + gamepad.get_virt_path())

	logger.debug("Finished configuring detected controllers")
	logger.debug("Updated Managed gamepads: " + str(gamepads.phys_paths()))


func _on_game_state_entered(_from: State) -> void:
	logger.debug("Ungrabbing gamepad interception")
	_set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS)


func _on_game_state_exited(_to: State) -> void:
	_on_game_state_removed()


func _on_game_state_removed() -> void:
	_set_intercept(ManagedGamepad.INTERCEPT_MODE.ALL)

	# Clear any gamepad profiles when no games are running
	logger.debug("Resetting gamepad profiles")
	for gamepad in gamepads.items():
		gamepad.set_profile(null)


func _get_event_from_phys(phys_path: String)  -> String:
	var event := phys_path.split("/")[-1] as String
	return event 


## Structure for looking up and maintaining Gamepads objects
class GamepadArray:
	var handheld: HandheldGamepad
	var gamepads: Array[ManagedGamepad] = []
	var gamepad_phys_paths: Array[String] = []
	var gamepad_virt_paths: Array[String] = []
	var mutex := Mutex.new()
	
	func add(gamepad: ManagedGamepad) -> void:
		mutex.lock()
		gamepads.append(gamepad)
		gamepad_phys_paths.append(gamepad.phys_path)
		gamepad_virt_paths.append(gamepad.virt_path)
		if gamepad is HandheldGamepad:
			handheld = gamepad
		mutex.unlock()

	func erase(gamepad: ManagedGamepad) -> void:
		mutex.lock()
		var idx := gamepads.find(gamepad)
		if idx == -1:
			mutex.unlock()
			return
		gamepads.remove_at(idx)
		gamepad_phys_paths.remove_at(idx)
		gamepad_virt_paths.remove_at(idx)
		mutex.unlock()

	func is_managed(path: String) -> bool:
		return path in gamepad_phys_paths or path in gamepad_virt_paths

	func has_handheld() -> bool:
		return handheld != null

	func phys_paths() -> Array[String]:
		mutex.lock()
		var paths := gamepad_phys_paths.duplicate()
		mutex.unlock()
		return paths
	
	func get_by_phys(phys_path: String) -> ManagedGamepad:
		mutex.lock()
		var idx := gamepad_phys_paths.find(phys_path)
		if idx == -1:
			mutex.unlock()
			return null
		var gamepad := gamepads[idx]
		mutex.unlock()
		return gamepad

	func items() -> Array[ManagedGamepad]:
		mutex.lock()
		var objects := gamepads.duplicate()
		mutex.unlock()
		return objects

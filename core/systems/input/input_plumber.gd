@icon("res://assets/icons/game-controller.svg")
extends Resource
class_name InputPlumber

## Manages routing input to and from InputPlumber.
##
## The InputPlumberManager class is responsible for handling dbus messages to and
## from the InputPlumber input manager daemon.

const INPUT_PLUMBER_BUS := "org.shadowblip.InputPlumber"
const INPUT_PLUMBER_PATH := "/org/shadowblip/InputPlumber"
const INPUT_PLUMBER_PREFIX := INPUT_PLUMBER_PATH + "/devices"
const INPUT_PLUMBER_MANAGER_PATH := "/org/shadowblip/InputPlumber/Manager"
const IFACE_MANAGER := "org.shadowblip.InputManager"
const IFACE_COMPOSITE_DEVICE := "org.shadowblip.Input.CompositeDevice"
const IFACE_EVENT_DEVICE := "org.shadowblip.Input.Source.EventDevice"
const IFACE_HIDRAW_DEVICE := "org.shadowblip.Input.Source.HIDRawDevice"
const IFACE_IIO_DEVICE := "org.shadowblip.Input.Source.IIODevice"
const IFACE_DBUS_DEVICE := "org.shadowblip.Input.DBusDevice"
const IFACE_GAMEPAD_DEVICE := "org.shadowblip.Input.Gamepad"
const IFACE_KEYBOARD_DEVICE := "org.shadowblip.Input.Keyboard"
const IFACE_MOUSE_DEVICE := "org.shadowblip.Input.Mouse"

const DEFAULT_PROFILE := "res://assets/gamepad/profiles/default.json"
const DEFAULT_GLOBAL_PROFILE := "user://data/gamepad/profiles/global_default.json"
const PROFILES_DIR := "user://data/gamepad/profiles"

enum INTERCEPT_MODE {
	NONE,
	PASS,
	ALL,
}

var logger := Log.get_logger("InputPlumber", Log.LEVEL.INFO)

var dbus := load("res://core/global/dbus_system.tres") as DBusManager
var manager := Manager.new(dbus.create_proxy(INPUT_PLUMBER_BUS, INPUT_PLUMBER_MANAGER_PATH))
var object_manager := dbus.ObjectManager.new(dbus.create_proxy(INPUT_PLUMBER_BUS, INPUT_PLUMBER_PATH))
var system_thread := load("res://core/systems/threading/system_thread.tres") as SharedThread

var is_running := false
var composite_devices: Array[CompositeDevice] = []
var composite_devices_map: Dictionary = {}
var intercept_mode_current: INTERCEPT_MODE = INTERCEPT_MODE.NONE
var intercept_triggers_current: PackedStringArray = ["Gamepad:Button:Guide"]
var intercept_target_current: String = "Gamepad:Button:Guide"

## Emitted when InputPlumber is detected as running
signal started
## Emitted when InputPlumber is detected as stopped
signal stopped
## Emitted when a CompositeDevice is dicovered and identified as a new device
signal composite_device_added(device: CompositeDevice)
## Emitted when a CompositeDevice is dicovered over dbus but already exists in
## the local map
signal composite_device_changed(device: CompositeDevice)
## Emitted when a CompositeDevice is removed
signal composite_device_removed(dbus_path: String)


func _init() -> void:
	logger.debug("Initalizing InputPlumber. Found composite devices: " + str(composite_devices))
	object_manager.interfaces_added.connect(_on_interfaces_added)
	object_manager.interfaces_removed.connect(_on_interfaces_removed)
	composite_devices = get_devices()
	for device in composite_devices:
		composite_devices_map[device.dbus_path] = device

	# Ensure the global default config is created
	var profiles_dir := ProjectSettings.globalize_path(PROFILES_DIR)
	if DirAccess.make_dir_recursive_absolute(profiles_dir) != OK:
		logger.error("Failed to create user profiles directory: " + profiles_dir)
		return
	var default_profile := FileAccess.open(DEFAULT_PROFILE, FileAccess.READ)
	var default_profile_data := default_profile.get_as_text()
	logger.debug("Writing default global profile to: " + DEFAULT_GLOBAL_PROFILE)
	var global_default_profile := FileAccess.open(DEFAULT_GLOBAL_PROFILE, FileAccess.WRITE)
	global_default_profile.store_string(default_profile_data)

	# Start a task that monitors whether or not InputPlumber is started or stopped,
	# and emits signals when its running state changes.
	started.connect(_on_inputplumber_started)
	stopped.connect(_on_inputplumber_stopped)
	var running_check := func():
		var update_running := func():
			var running := dbus.bus_exists(INPUT_PLUMBER_BUS)
			if running == self.is_running:
				return
			self.is_running = running
			if running:
				started.emit()
			else:
				stopped.emit()
		update_running.call_deferred()
	system_thread.exec(running_check)
	system_thread.scheduled_exec(running_check, 5000, SharedThread.ScheduledTaskType.RECURRING)


func _on_inputplumber_started() -> void:
	logger.info("InputPlumber started")
	
	# Remove any Godot gamepad input maps and rely completely on InputPlumber for
	# gamepad input
	var actions := InputMap.get_actions()
	var to_erase: Array[InputEvent] = []
	for action in actions:
		var events := InputMap.action_get_events(action)
		for event in events:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				logger.debug("Erasing mapping for", action, ":", event)
				InputMap.action_erase_event(action, event)


func _on_inputplumber_stopped() -> void:
	logger.warn("InputPlumber stopped")
	
	# Reload Godot input mappings if InputPlumber shuts down
	logger.debug("Restoring input mappings from project settings")
	InputMap.load_from_project_settings()


func _on_interfaces_added(dbus_path: String) -> void:
	logger.debug("Interfaces Added: " + str(dbus_path))
	if not "CompositeDevice" in dbus_path:
		return
	composite_devices = get_devices(dbus_path)
	composite_devices_map.clear()
	for device in composite_devices:
		composite_devices_map[device.dbus_path] = device


func _on_interfaces_removed(dbus_path: String) -> void:
	logger.debug("Interfaces Removed: " + str(dbus_path))
	if not "CompositeDevice" in dbus_path:
		return
	composite_devices = get_devices()
	composite_devices_map.clear()
	for device in composite_devices:
		composite_devices_map[device.dbus_path] = device
	if dbus_path.contains("CompositeDevice"):
		composite_device_removed.emit(dbus_path)


## Returns true if InputPlumber can be used on this system
func supports_input_plumber() -> bool:
	return dbus.bus_exists(INPUT_PLUMBER_BUS)


func get_objects_of(pattern: String) -> Array:
	var devices: Array = []
	var device_paths := dbus.get_managed_objects(INPUT_PLUMBER_BUS, INPUT_PLUMBER_PATH)
	logger.debug("Searching for " + pattern + " objects.")
	# Loop through all objects on the bus
	for obj in device_paths:
		
		var object := obj as DBusManager.ManagedObject
		var path := object.path
		var proxy := dbus.create_proxy(INPUT_PLUMBER_BUS, path)
		#logger.debug("Found object: " + str(object) + " with path " + path)
		if path.contains(pattern) and pattern == "CompositeDevice":
			logger.debug("Found " + pattern + " in " + path)
			var device := CompositeDevice.new(proxy)
			devices.append(device)
			continue

		if path.contains(pattern) and pattern == "event":
			var device := EventDevice.new(proxy)
			devices.append(device)
			continue

		if path.contains(pattern) and pattern == "hidraw":
			var device := HIDRawDevice.new(proxy)
			devices.append(device)
			continue

		if path.contains(pattern) and pattern == "iio":
			var device := IIODevice.new(proxy)
			devices.append(device)
			continue

		if path.contains(pattern) and pattern == "dbus":
			var device := DBusDevice.new(proxy)
			devices.append(device)
			continue

		if path.contains(pattern) and pattern == "gamepad":
			var device := GamepadDevice.new(proxy)
			devices.append(device)
			continue

		if path.contains(pattern) and pattern == "keyboard":
			var device := KeyboardDevice.new(proxy)
			devices.append(device)
			continue

		if path.contains(pattern) and pattern == "mouse":
			var device := MouseDevice.new(proxy)
			devices.append(device)
			continue
	logger.debug("Returning devices: " + str(devices))
	return devices


## Retrieves all CompositeDevices currently on the InputPlumber DBus interface. Will
## emit composite_device_added if the given dbus path is a new device, or
## composite_device_changed if it already existed
func get_devices(dbus_path: String = "") -> Array[CompositeDevice]:
	logger.debug("Getting all composite devices.")
	var new_device_list: Array[CompositeDevice]
	new_device_list.assign(get_objects_of("CompositeDevice"))
	var existing_devices: Array[CompositeDevice]

	# Only return new devices. Overriding devices breaks signaling.
	for device in new_device_list:
		var found: bool = false
		for old_dev in composite_devices:
			if old_dev.dbus_path == device.dbus_path:
				existing_devices.append(old_dev)
				found = true
				if dbus_path == device.dbus_path:
					composite_device_changed.emit(device)
				break

		# New device found
		if not found:
			existing_devices.append(device)
			set_intercept_mode_single(intercept_mode_current, device)
			set_intercept_activation_single(intercept_triggers_current, \
				intercept_target_current, device)
			composite_device_added.emit(device)

	return existing_devices


## Returns the [CompositeDevice] with the given DBus path
func get_device(dbus_path: String) -> CompositeDevice:
	if dbus_path in composite_devices_map:
		return composite_devices_map[dbus_path]
	return null


## Sets all composite devices to the specified intercept mode.
func set_intercept_mode(mode: INTERCEPT_MODE) -> void:
	logger.debug("Setting all composite devices to mode: " + str(mode))
	intercept_mode_current = mode
	for d in composite_devices:
		var device := d as CompositeDevice
		set_intercept_mode_single(mode, device)


func set_intercept_mode_single(mode: INTERCEPT_MODE, device: CompositeDevice) -> void:
	logger.debug("Setting composite device "+ device.dbus_path + " to mode: " + str(mode))
	match mode:
			INTERCEPT_MODE.NONE:
				device.intercept_mode = 0
			INTERCEPT_MODE.PASS:
				device.intercept_mode = 1
			INTERCEPT_MODE.ALL:
				device.intercept_mode = 2


## Sets all composite devices to use the specified intercept actions.
func set_intercept_activation(triggers: PackedStringArray, target: String) -> void:
	logger.debug("Setting all composite devices to intercept triggers: " + str(triggers) + " and target event: " + target)
	intercept_triggers_current = triggers
	intercept_target_current = target
	for d in composite_devices:
		var device := d as CompositeDevice
		set_intercept_activation_single(triggers, target, device)


func set_intercept_activation_single(triggers: PackedStringArray, target: String, device: CompositeDevice) -> void:
	logger.debug("Setting composite device "+ device.dbus_path + " intercept triggers: " + str(triggers) + " and target event: " + target)
	device.set_intercept_activation(triggers, target)


class Manager extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	func create_composite_device(config_path: String) -> String:
		var result := _proxy.call_method(IFACE_MANAGER, "CreateCompositeDevice", [config_path])
		if not result:
			return ""
		var args := result.get_args()
		if args.size() != 1:
			return ""
		if not args[0] is String:
			return ""
		return args[0]


class CompositeDevice extends Resource:
	signal updated
	
	var _proxy: DBusManager.Proxy
	var dbus_targets: Array[DBusDevice]
	var dbus_path: String
	var logger := Log.get_logger("InputPlumber CompositeDevice", Log.LEVEL.INFO)

	func _init(proxy: DBusManager.Proxy) -> void:
		var dbus := load("res://core/global/dbus_system.tres") as DBusManager
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)
		for path in self.dbus_devices:
			var device := DBusDevice.new(dbus.create_proxy(INPUT_PLUMBER_BUS, path))
			dbus_targets.append(device)
		dbus_path = _proxy.path

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()
		
	var name: String:
		get:
			var property = _proxy.get_property(IFACE_COMPOSITE_DEVICE, "Name")
			if not property is String:
				return ""
			return property

	var profile_name: String:
		get:
			var property = _proxy.get_property(IFACE_COMPOSITE_DEVICE, "ProfileName")
			if not property is String:
				return ""
			return property

	var intercept_mode: int:
		set(v):
			#print("Setting mode " + str(v) + " on " + self.dbus_path)
			_proxy.set_property(IFACE_COMPOSITE_DEVICE, "InterceptMode", DBus.uint32(v))
		get:
			var property = _proxy.get_property(IFACE_COMPOSITE_DEVICE, "InterceptMode")
			if not property is int:
				return -1
			return property

	var capabilities: PackedStringArray:
		get:
			var property = _proxy.get_property(IFACE_COMPOSITE_DEVICE, "Capabilities")
			if not property is Array:
				return []
			return property

	var target_capabilities: PackedStringArray:
		get:
			var property = _proxy.get_property(IFACE_COMPOSITE_DEVICE, "TargetCapabilities")
			if not property is Array:
				return []
			return property

	var dbus_devices: PackedStringArray:
		get:
			var property = _proxy.get_property(IFACE_COMPOSITE_DEVICE, "DbusDevices")
			if not property is Array:
				return []
			return property

	var source_device_paths: PackedStringArray:
		get:
			var property = _proxy.get_property(IFACE_COMPOSITE_DEVICE, "SourceDevicePaths")
			if not property is Array:
				return []
			return property

	var target_devices: PackedStringArray:
		get:
			var property = _proxy.get_property(IFACE_COMPOSITE_DEVICE, "TargetDevices")
			if not property is Array:
				return []
			return property

	func set_target_devices(devices: PackedStringArray) -> void:
		_proxy.call_method( IFACE_COMPOSITE_DEVICE, "SetTargetDevices", [devices], "as")

	## Load the given profile on the composite device, optionally specifying a profile
	## modifier, which is a target device string (e.g. "deck", "ds5-edge", etc.) to
	## adapt the profile for. This will update the profile with target-specific
	## defaults, like mapping left/right pads to the DualSense center pad if no
	## other mappings are defined.
	func target_modify_profile(path: String, profile_modifier: String = "") -> void:
		logger.debug("Loading Profile:", path)
		if path == "" or not path.ends_with(".json") or not FileAccess.file_exists(path):
			logger.error("Profile path:", path," is not a valid profile path.")
			return
		if profile_modifier.is_empty():
			load_profile_path(path)
			return

		var profile := InputPlumberProfile.load(path)

		var c_pad_cap = "Touchpad:CenterPad:Motion"
		var l_pad_cap = "Touchpad:LeftPad:Motion"
		var r_pad_cap = "Touchpad:RightPad:Motion"
		var mouse_cap = "Mouse:Motion"

		if !profile_modifier.is_empty():
			var mapped_capabilities := profile.to_json()
			logger.debug("Mapped Capabilities (before):", mapped_capabilities)
			match profile_modifier:
					"deck":
						logger.debug("Steam Deck Profile")
						if c_pad_cap not in mapped_capabilities:
							logger.debug("Map", c_pad_cap)
							var c_pad_map := InputPlumberMapping.from_source_capability(c_pad_cap)
							var r_pad_event := InputPlumberEvent.from_capability(r_pad_cap)
							c_pad_map.target_events = [r_pad_event]
							profile.mapping.append(c_pad_map)

					"ds5", "ds5-edge":
						logger.debug("Dualsense Profile")
						if l_pad_cap not in mapped_capabilities:
							logger.debug("Map", l_pad_cap)
							var l_pad_map := InputPlumberMapping.from_source_capability(l_pad_cap)
							var c_pad_event := InputPlumberEvent.from_capability(c_pad_cap)
							l_pad_map.target_events = [c_pad_event]
							profile.mapping.append(l_pad_map)
						if r_pad_cap not in mapped_capabilities:
							logger.debug("Map", r_pad_cap)
							var r_pad_map := InputPlumberMapping.from_source_capability(r_pad_cap)
							var c_pad_event := InputPlumberEvent.from_capability(c_pad_cap)
							r_pad_map.target_events = [c_pad_event]
							profile.mapping.append(r_pad_map)

					_:
						logger.debug("Target device needs no modifications:", profile_modifier)

			mapped_capabilities = profile.to_json()
			logger.debug("Mapped Capabilities (after):", mapped_capabilities)

		path = path.rstrip(".json") + profile_modifier + ".json"
		if profile.save(path) != OK:
			logger.error("Failed to save", profile.name, "to", path)
			return
		load_profile_path(path)

	func load_profile_path(path: String) -> void:
		# Get the absolute path if this is a resource path
		var absolute_path := path
		if path.begins_with("res://") or path.begins_with("user://"):
			absolute_path = ProjectSettings.globalize_path(path)
		_proxy.call_method(IFACE_COMPOSITE_DEVICE, "LoadProfilePath", [absolute_path], "s")

	func send_event(action: String, value: Variant) -> void:
		_proxy.call_method( IFACE_COMPOSITE_DEVICE, "SendEvent", [action, value], "sv")

	func send_button_chord(actions: PackedStringArray) -> void:
		_proxy.call_method( IFACE_COMPOSITE_DEVICE, "SendButtonChord", [actions], "as")

	func set_intercept_activation(triggers: PackedStringArray, target_event: String) -> void:
		_proxy.call_method( IFACE_COMPOSITE_DEVICE, "SetInterceptActivation", [triggers, target_event], "ass")


class EventDevice extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	var name: String:
		get:
			var property = _proxy.get_property(IFACE_EVENT_DEVICE, "Name")
			if not property is String:
				return ""
			return property

	var device_path: String:
		get:
			var property = _proxy.get_property(IFACE_EVENT_DEVICE, "DevicePath")
			if not property is String:
				return ""
			return property

	var phys_path: String:
		get:
			var property = _proxy.get_property(IFACE_EVENT_DEVICE, "PhysPath")
			if not property is String:
				return ""
			return property

	var sysfs_path: String:
		get:
			var property = _proxy.get_property(IFACE_EVENT_DEVICE, "SysfsPath")
			if not property is String:
				return ""
			return property

	var unique_id: String:
		get:
			var property = _proxy.get_property(IFACE_EVENT_DEVICE, "UniqueId")
			if not property is String:
				return ""
			return property

	var handlers: PackedStringArray:
		get:
			var property = _proxy.get_property(IFACE_EVENT_DEVICE, "Handlers")
			if not property is Array:
				return []
			return property


class HIDRawDevice extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	var interface_number: int:
		get:
			var property = _proxy.get_property(IFACE_HIDRAW_DEVICE, "InterfaceNumber")
			if not property is int:
				return -1
			return property

	var manufacturer: String:
		get:
			var property = _proxy.get_property(IFACE_HIDRAW_DEVICE, "Manufacturer")
			if not property is String:
				return ""
			return property

	var path: String:
		get:
			var property = _proxy.get_property(IFACE_HIDRAW_DEVICE, "Path")
			if not property is String:
				return ""
			return property

	var product: String:
		get:
			var property = _proxy.get_property(IFACE_HIDRAW_DEVICE, "Product")
			if not property is String:
				return ""
			return property

	var product_id: String:
		get:
			var property = _proxy.get_property(IFACE_HIDRAW_DEVICE, "ProductId")
			if not property is String:
				return ""
			return property

	var release_number: String:
		get:
			var property = _proxy.get_property(IFACE_HIDRAW_DEVICE, "ReleaseNumber")
			if not property is String:
				return ""
			return property

	var serial_number: String:
		get:
			var property = _proxy.get_property(IFACE_HIDRAW_DEVICE, "SerialNumber")
			if not property is String:
				return ""
			return property

	var vendor_id: String:
		get:
			var property = _proxy.get_property(IFACE_HIDRAW_DEVICE, "VendorId")
			if not property is String:
				return ""
			return property


class IIODevice extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	var id: String:
		get:
			var property = _proxy.get_property(IFACE_IIO_DEVICE, "Id")
			if not property is int:
				return ""
			return property

	var name: String:
		get:
			var property = _proxy.get_property(IFACE_IIO_DEVICE, "Name")
			if not property is String:
				return ""
			return property


class KeyboardDevice extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	var name: String:
		get:
			var property = _proxy.get_property(IFACE_KEYBOARD_DEVICE, "Name")
			if not property is String:
				return ""
			return property

	func send_key(key: String, pressed: bool) -> void:
		_proxy.call_method(IFACE_KEYBOARD_DEVICE, "SendKey", [key, pressed])


class MouseDevice extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	var name: String:
		get:
			var property = _proxy.get_property(IFACE_MOUSE_DEVICE, "Name")
			if not property is String:
				return ""
			return property


class GamepadDevice extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	var name: String:
		get:
			var property = _proxy.get_property(IFACE_GAMEPAD_DEVICE, "Name")
			if not property is String:
				return ""
			return property


class DBusDevice extends Resource:
	signal input_event(type_code: String, value: float)
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		#print("Creating DBusDevice!")
		_proxy = proxy
		_proxy.message_received.connect(_on_message_received)
		_proxy.thread.exec(_proxy.watch.bind(IFACE_DBUS_DEVICE, "InputEvent"))

	func _on_message_received(msg: DBusMessage) -> void:
		if not msg:
			return
		if msg.get_member() != "InputEvent":
			return
		var args := msg.get_args()
		if args.size() < 2:
			return
		#print("Got InputEvent " + str(args))
		#print(str(self.get_instance_id()))
		#print(str(self.get_rid()))
		input_event.emit(args[0], args[1])

	var name: String:
		get:
			var property = _proxy.get_property(IFACE_DBUS_DEVICE, "Name")
			if not property is String:
				return ""
			return property

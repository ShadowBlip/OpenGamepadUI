extends Control

const USER_TEMPLATES := "user://data/gamepad/templates"
const USER_PROFILES := "user://data/gamepad/profiles"
const DEFAULT_PROFILE := "res://assets/gamepad/profiles/default.json"

var change_input_state := preload("res://assets/state/states/gamepad_change_input.tres") as State
var gamepad_state := load("res://assets/state/states/gamepad_settings.tres") as State
var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var state_machine := load("res://assets/state/state_machines/gamepad_settings_state_machine.tres") as StateMachine
var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumber
var button_scene := load("res://core/ui/components/card_mapping_button.tscn") as PackedScene

var gamepad: InputPlumber.CompositeDevice
var profile: InputPlumberProfile
var library_item: LibraryItem
var gamepad_types := ["Generic Gamepad", "XBox 360", "DualSense", "DualSense Edge", "Steam Deck"]
var gamepad_types_icons := ["XBox 360", "XBox 360", "PS5", "PS5", "Steam Deck"] # From res://assets/gamepad/icon_mappings
var gamepad_type_selected := 0
var buttons: Dictionary = {}
var logger := Log.get_logger("GamepadSettings", Log.LEVEL.DEBUG)

@onready var main_container := $%MainContainer as Container
@onready var not_available := $%ServiceNotAvailableContainer as Container
@onready var container := $%ButtonMappingContainer as Container
@onready var mapping_focus_group := $%MappingFocusGroup as FocusGroup
@onready var previous_axis_focus_group := mapping_focus_group as FocusGroup
@onready var gamepad_mapper := $%GamepadMapper as GamepadMapper
@onready var save_button := $%SaveButton as CardIconButton
@onready var delete_button := $%DeleteButton as CardIconButton
@onready var profile_label := $%ProfileNameLabel as Label
@onready var gamepad_type_dropdown := %GamepadTypeDropdown as Dropdown


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gamepad_state.state_entered.connect(_on_state_entered)
	gamepad_state.state_exited.connect(_on_state_exited)
	gamepad_mapper.mapping_selected.connect(_on_mapping_selected)
	#save_button.button_up.connect(_save_profile)

	# On delete button pressed, reset profile to default
	var on_delete := func():
		profile = _load_profile()
		_update_buttons()
	delete_button.button_up.connect(on_delete)
	
	# Setup the gamepad type dropdown
	gamepad_type_dropdown.clear()
	for gamepad_type in self.gamepad_types:
		gamepad_type_dropdown.add_item(gamepad_type)
	var on_gamepad_selected := func(item_selected: int):
		self.gamepad_type_selected = item_selected
		if self.profile:
			var gamepad_type := self.get_selected_target_gamepad()
			self.profile.target_devices = [
				gamepad_type,
				InputPlumberProfile.TargetDevice.Mouse,
				InputPlumberProfile.TargetDevice.Keyboard,
			]
		self._update_buttons()
	gamepad_type_dropdown.item_selected.connect(on_gamepad_selected)
	
	# Grab focus when the mapper exits
	var on_state_changed := func(_from: State, to: State):
		if to:
			return
		mapping_focus_group.grab_focus()
	state_machine.state_changed.connect(on_state_changed)


## Called when the gamepad settings state is entered
func _on_state_entered(_from: State) -> void:
	# Ensure that InputPlumber is running
	if not input_plumber.supports_input_plumber():
		not_available.visible = true
		main_container.visible = false
		$ServiceNotAvailableContainer/Label.text = "InputPlumber service not available"
		return
	not_available.visible = false
	main_container.visible = true
	
	# Read from the state to determine which gamepad is being configured
	gamepad = null
	if !gamepad_state.has_meta("dbus_path"):
		logger.error("No gamepad was set to configure!")
		# Make menu empty, unable to find gamepad to configure
		not_available.visible = true
		main_container.visible = false
		$ServiceNotAvailableContainer/Label.text = "No gamepad to configure"
		return
	var dbus_path := gamepad_state.get_meta("dbus_path") as String
	logger.debug("Configuring gamepad: " + dbus_path)
	
	# Find the composite device to configure
	for device: InputPlumber.CompositeDevice in input_plumber.composite_devices:
		if device.dbus_path == dbus_path:
			gamepad = device
			break
	if gamepad == null:
		logger.error("Unable to find CompositeDevice with path: " + dbus_path)
		not_available.visible = true
		main_container.visible = false
		$ServiceNotAvailableContainer/Label.text = "No gamepad to configure"
		return
	
	# Populate the menu with the source inputs for the given gamepad
	populate_mappings_for(gamepad)

	library_item = null
	profile = null
	if gamepad_state.has_meta("item"):
		library_item = gamepad_state.get_meta("item") as LibraryItem

	# If no library item was set with the state, then configure the OGUI profile
	if not library_item:
		profile_label.text = "Global"
		var profile_path := settings_manager.get_value("input", "gamepad_profile", "") as String
		if profile_path == "":
			profile = InputPlumberProfile.load(DEFAULT_PROFILE)
			_update_buttons()
			return
		profile = _load_profile(profile_path)
		_update_buttons()
		return

	# Set the profile text to the game name
	profile_label.text = library_item.name

	# Check to see if the given game has a gamepad profile
	var profile_path := settings_manager.get_library_value(library_item, "gamepad_profile", "") as String
	profile = _load_profile(profile_path)
	_update_buttons()


func _on_state_exited(_to: State) -> void:
	if not self.profile:
		return
	_save_profile()


## Invoked when a gamepad mapping is selected
func _on_mapping_selected(mapping: InputPlumberMapping) -> void:
	if not mapping:
		logger.warn("No valid mapping provided")
		return
	if not profile:
		logger.warn("Gamepad profile is null!")
		return
	
	# Remove any existing mappings with this source event
	var to_remove: Array[InputPlumberMapping] = []
	for existing_mapping: InputPlumberMapping in profile.mapping:
		if mapping.source_event.matches(existing_mapping.source_event):
			to_remove.append(existing_mapping)
	for map in to_remove:
		logger.debug("Removing old mapping: " + str(map))
		profile.mapping.erase(map)
	
	# Add the mapping to the profile
	logger.debug("Adding mapping: " + str(mapping))
	profile.mapping.append(mapping)

	logger.debug("Reloading profile")
	_update_buttons()


## Populates the button mappings for the given gamepad
func populate_mappings_for(gamepad: InputPlumber.CompositeDevice) -> void:
	var capabilities := gamepad.capabilities
	logger.debug("Found capabilities for gamepad: " + str(capabilities))

	# Delete any old buttons
	for child in container.get_children():
		if child is CardMappingButton:
			child.queue_free()
	
	# Reset any focus group neighbors
	previous_axis_focus_group = mapping_focus_group 

	# Clear our button mapping 
	buttons = {}

	# Organize all the capabilities
	var button_events := PackedStringArray()
	var axes_events := PackedStringArray()
	var trigger_events := PackedStringArray()
	var accel_events := PackedStringArray()
	var gyro_events := PackedStringArray()
	var touchpad_events := PackedStringArray()
	for capability: String in capabilities:
		logger.debug("Capability: " + capability)
		if capability.begins_with("Gamepad:Button"):
			button_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Axis"):
			axes_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Trigger"):
			trigger_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Accelerometer"):
			accel_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Gyro"):
			gyro_events.append(capability)
			continue
		if capability.begins_with("TouchPad:"):
			touchpad_events.append(capability)
			continue
		logger.warn("Unhandled capability: " + capability)
	
	# Create all the button mappings
	var label := $%ButtonsLabel
	label.visible = button_events.size() > 0
	for capability in button_events:
		_add_button_for_capability(capability, label)

	label = $%AxesLabel
	label.visible = axes_events.size() > 0
	for capability in axes_events:
		_add_button_for_capability(capability, label)

	label = $%TriggersLabel
	label.visible = trigger_events.size() > 0
	for capability in trigger_events:
		_add_button_for_capability(capability, label)

	label = $%AccelerometerLabel
	label.visible = accel_events.size() > 0
	for capability in accel_events:
		_add_button_for_capability(capability, label)

	label = $%GyroLabel
	label.visible = gyro_events.size() > 0
	for capability in gyro_events:
		_add_button_for_capability(capability, label)

	label = $%TouchpadsLabel
	label.visible = touchpad_events.size() > 0
	for capability in touchpad_events:
		_add_button_for_capability(capability, label)


## Create a card mapping button for the given event under the given parent
func _add_button_for_capability(capability: String, parent: Node) -> CardMappingButton:
	var idx := parent.get_index() + 1

	var button := button_scene.instantiate() as CardMappingButton
	button.text = "-"
	var on_button_ready := func():
		var icon_mapping := get_selected_target_gamepad_icon_map()
		button.set_target_device_icon_mapping(icon_mapping)
		button.set_source_device_icon_mapping(gamepad.name)
		button.set_source_capability(capability)
	button.ready.connect(on_button_ready, CONNECT_ONE_SHOT)

	# Add the button to our button map
	buttons[capability] = button

	# Create a gamepad profile mapping when pressed
	var on_pressed := func():
		# Create a new mapping for this button
		var mapping := InputPlumberMapping.new()
		mapping.name = capability
		var source_event := InputPlumberEvent.new()
		if source_event.set_capability(capability) != OK:
			logger.error("Failed to set source event with capability: " + capability)
			return
		mapping.source_event = source_event
		
		# Switch to change_input_state with the selected mapping to be updated
		var texture: Texture
		if button.source_icon.textures.size() > 0:
			texture = button.source_icon.textures[0]
		change_input_state.set_meta("texture", texture)
		change_input_state.set_meta("mappings", mapping)
		change_input_state.set_meta("gamepad", self.gamepad)
		change_input_state.set_meta("gamepad_type", self.gamepad_types[self.gamepad_type_selected])
		change_input_state.set_meta("gamepad_type_icon_map", self.gamepad_types_icons[self.gamepad_type_selected])
		state_machine.push_state(change_input_state)
	button.button_up.connect(on_pressed)

	# Add the button to the container and move it just under the given parent
	container.add_child(button)
	container.move_child(button, idx)

	return button


## Syncs the UI to the given profile
func _update_buttons() -> void:
	if not profile:
		return
	profile_label.text = profile.name

	# Update the dropdown based on the profile's target gamepad type
	if profile.target_devices and profile.target_devices.size() > 0:
		for target_device in profile.target_devices:
			if target_device in [InputPlumberProfile.TargetDevice.Keyboard, InputPlumberProfile.TargetDevice.Mouse]:
				continue
			var gamepad_text := self.get_target_gamepad_text(target_device)
			var i := 0
			var idx := 0
			for item in self.gamepad_types:
				if item == gamepad_text:
					idx = i
					break
				i += 1
			gamepad_type_dropdown.select(idx)
			break

	# Reset the button text
	for button: CardMappingButton in buttons.values():
		button.text = "-"

	# Set the button text based on the loaded profile
	for mapping: InputPlumberMapping in profile.mapping:
		var source_event := mapping.source_event
		var capability := source_event.to_capability()
		if not capability:
			logger.debug("Unable to find capability for mapping: " + str(mapping))
			continue

		# Find the button for this mapping
		if not capability in buttons:
			logger.debug("Unable to find button for capability: " + capability)
			continue
		var button := buttons[capability] as CardMappingButton

		# Update the button using the given mapping
		_update_button(button, mapping)


## Update the button using the given mapping
func _update_button(button: CardMappingButton, mapping: InputPlumberMapping) -> void:
	button.text = ""
	var icon_mapping := get_selected_target_gamepad_icon_map()
	logger.debug("Using target icon mapping: " + icon_mapping)
	button.set_target_device_icon_mapping(icon_mapping)
	for event in mapping.target_events:
		button.set_target_capability(event.to_capability())
		# TODO: Figure out what to display if this maps to multiple inputs
		break


## Get the text to display on the mapping button from the given event
#func _get_display_string_for(event: MappableEvent) -> String:
	#if event is NativeEvent:
		#var native_event := event as NativeEvent
		#if native_event.event is InputEventKey:
			#var key_event := native_event.event as InputEventKey
			#return key_event.as_text()
		#if native_event.event is InputEventMouseMotion:
			#return "Mouse motion"
		#if native_event.event is InputEventMouseButton:
			#var mouse_event := native_event.event as InputEventMouseButton
			#if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				#return "Left mouse click"
			#if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
				#return "Middle mouse click"
			#if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
				#return "Right mouse click"
			#if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				#return "Mouse wheel up"
			#if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				#return "Mouse wheel down"
	#if event is EvdevEvent:
		#return ControllerMapper.get_joypad_path_from_event(event)
#
	#return ""


## Returns the InputPlumber gamepad string based on the currently selected
## gamepad type in the dropdown
func get_selected_target_gamepad() -> InputPlumberProfile.TargetDevice:
	var selected_gamepad := self.gamepad_types[self.gamepad_type_selected] as String
	match selected_gamepad:
		"Generic Gamepad":
			return InputPlumberProfile.TargetDevice.Gamepad
		"XBox 360":
			return InputPlumberProfile.TargetDevice.XBox360
		"DualSense":
			return InputPlumberProfile.TargetDevice.DualSenseEdge
		"DualSense Edge":
			return InputPlumberProfile.TargetDevice.DualSenseEdge
		"Steam Deck":
			return InputPlumberProfile.TargetDevice.SteamDeck

	return InputPlumberProfile.TargetDevice.Gamepad


## Returns the name of the gamepad icon map to use for target capabilities
func get_selected_target_gamepad_icon_map() -> String:
	var selected_target_icon_map := self.gamepad_types_icons[self.gamepad_type_dropdown.selected] as String
	return selected_target_icon_map


## Returns the gamepad type text for the given InputPlumber gamepad string
func get_target_gamepad_text(gamepad_type: InputPlumberProfile.TargetDevice) -> String:
	match gamepad_type:
		InputPlumberProfile.TargetDevice.Gamepad:
			return "Generic Gamepad"
		InputPlumberProfile.TargetDevice.XBox360:
			return "XBox 360"
		InputPlumberProfile.TargetDevice.DualSense:
			return "DualSense"
		InputPlumberProfile.TargetDevice.DualSenseEdge:
			return "DualSense Edge"
		InputPlumberProfile.TargetDevice.SteamDeck:
			return "Steam Deck"

	return "Generic Gamepad"


# Save the current profile to a file
func _save_profile() -> void:
	var notify := Notification.new("")
	if not profile:
		logger.debug("No profile loaded to save")
		return
	if not library_item:
		# TODO: Fix for global
		logger.debug("No library item loaded to associate profile with")
		return

	# Try to save the profile
	var filename := library_item.name.sha256_text() + ".json"
	var path := "/".join([USER_PROFILES, filename])
	if profile.save(path) != OK:
		logger.error("Failed to save gamepad profile to: " + path)
		notify.text = "Failed to save gamepad profile"
		notification_manager.show(notify)
		return

	# Update the game settings to use this gamepad profile
	var section := "game.{0}".format([library_item.name.to_lower()])
	settings_manager.set_value(section, "gamepad_profile", path)
	logger.debug("Saved gamepad profile to: " + path)
	notify.text = "Gamepad profile saved"
	notification_manager.show(notify)

	# Update/reload the saved profile
	#profile = ResourceLoader.load(path, "GamepadProfile", ResourceLoader.CACHE_MODE_IGNORE)
	var running_app := launch_manager.get_current_app()
	if running_app:
		if running_app.launch_item.name != library_item.name:
			pass
		logger.debug("Reloading gamepad profile for running game")
		launch_manager.set_gamepad_profile(path)


# Load the given gamepad profile. Returns the default gamepad profile if the 
# given profile does not exist.
func _load_profile(profile_path: String = "") -> InputPlumberProfile:
	var loaded: InputPlumberProfile
	if profile_path == "" or not FileAccess.file_exists(profile_path):
		loaded = InputPlumberProfile.load(DEFAULT_PROFILE)
		if not loaded:
			loaded = InputPlumberProfile.new()
		if library_item:
			loaded.name = library_item.name
		return loaded

	loaded = InputPlumberProfile.load(profile_path)

	return loaded

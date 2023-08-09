extends Control

const user_templates := "user://data/gamepad/templates"
const user_profiles := "user://data/gamepad/profiles"

var gamepad_manager := load("res://core/systems/input/gamepad_manager.tres") as GamepadManager
var change_input_state := preload("res://assets/state/states/gamepad_change_input.tres") as State
var gamepad_state := load("res://assets/state/states/gamepad_settings.tres") as State
var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var state_machine := load("res://assets/state/state_machines/gamepad_settings_state_machine.tres") as StateMachine

var button_scene := load("res://core/ui/components/card_mapping_button.tscn") as PackedScene
var axes_container_scene := load("res://core/ui/components/card_axes_mapping_container.tscn") as PackedScene
var dropdown_scene := load("res://core/ui/components/dropdown.tscn") as PackedScene
var profile: GamepadProfile
var library_item: LibraryItem
var buttons: Dictionary = {}
var axes_containers: Array[CardAxesMappingContainer] = []
var logger := Log.get_logger("GamepadSettings", Log.LEVEL.DEBUG)

@onready var container := $%ButtonMappingContainer as Container
@onready var mapping_focus_group := $%MappingFocusGroup as FocusGroup
@onready var previous_axis_focus_group: FocusGroup = mapping_focus_group
@onready var gamepad_mapper := $%GamepadMapper as GamepadMapper
@onready var save_button := $%SaveButton as CardIconButton
@onready var delete_button := $%DeleteButton as CardIconButton
@onready var profile_label := $%ProfileNameLabel as Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gamepad_state.state_entered.connect(_on_state_entered)
	gamepad_mapper.mappings_selected.connect(_on_mapping_selected)
	save_button.button_up.connect(_save_profile)

	# On delete button pressed, reset profile to default
	var on_delete := func():
		profile = _load_profile()
		_load_profile_ui()
	delete_button.button_up.connect(on_delete)
	
	# Grab focus when the mapper exits
	var on_state_changed := func(_from: State, to: State):
		if to:
			return
		mapping_focus_group.grab_focus()
	state_machine.state_changed.connect(on_state_changed)


## Invoked when a gamepad mapping is selected
func _on_mapping_selected(mappings: Array[GamepadMapping]) -> void:
	if not profile:
		logger.warn("Gamepad profile is null!")
		return
	
	for mapping in mappings:
		var source_event := mapping.source_event
		# Remove old mappings
		var to_remove := []
		for map in profile.mapping:
			if source_event.matches(map.source_event):
				to_remove.append(map)
		for map in to_remove:
			logger.debug("Removing old mapping: " + str(map))
			profile.mapping.erase(map)
		if mapping.output_events.size() > 0:
			logger.debug("Adding mapping: " + str(mapping))
			profile.mapping.append(mapping)
		logger.debug("Reloading profile")
	_load_profile_ui()


## Called when the gamepad settings state is entered
func _on_state_entered(_from: State) -> void:
	var gamepads := gamepad_manager.get_gamepad_paths()
	# TODO: Configure the menu per-gamepad to support multiple gamepads
	if gamepads.size() == 0:
		return
	populate_mappings_for(gamepads[0])

	library_item = null
	profile = null
	if gamepad_state.has_meta("item"):
		library_item = gamepad_state.get_meta("item") as LibraryItem

	# If no library item was set with the state, then configure the OGUI profile
	if not library_item:
		profile_label.text = "Global"
		var profile_path := settings_manager.get_value("input", "gamepad_profile", "") as String
		if profile_path == "":
			profile = load(gamepad_manager.default_profile)
			return
		profile = _load_profile(profile_path)
		_load_profile_ui()
		return

	# Set the profile text to the game name
	profile_label.text = library_item.name

	# Check to see if the given game has a gamepad profile
	var profile_path := settings_manager.get_library_value(library_item, "gamepad_profile", "") as String
	profile = _load_profile(profile_path)
	_load_profile_ui()


## Populates the button mappings for the given gamepad
func populate_mappings_for(gamepad_path: String) -> void:
	var capabilities := gamepad_manager.get_gamepad_capabilities(gamepad_path)

	# Delete any old buttons
	for child in container.get_children():
		if child is CardMappingButton:
			child.queue_free()
		if child is CardAxesMappingContainer:
			child.queue_free()
	
	# Reset any focus group neighbors
	previous_axis_focus_group = mapping_focus_group 

	# Clear our button mapping 
	buttons = {}
	axes_containers.clear()

	# Organize all the capabilities
	var button_events: Array[EvdevKeyEvent] = []
	var key_events: Array[EvdevKeyEvent] = []
	var axes_events := AxesArray.new()
	for event in capabilities:
		if event is EvdevKeyEvent:
			var code_name := event.to_input_device_event().get_code_name() as String
			if code_name.begins_with("BTN"):
				button_events.append(event)
				continue
			key_events.append(event)
			continue
		elif event is EvdevAbsEvent:
			var code_name := event.to_input_device_event().get_code_name() as String
			var axis_pair := AxisPair.new()
			if code_name.ends_with("_X"):
				axis_pair.type = AxisPair.TYPE.LEFT_JOY
				axis_pair.x_axis = event
			elif code_name.ends_with("_Y"):
				axis_pair.type = AxisPair.TYPE.LEFT_JOY
				axis_pair.y_axis = event
			elif code_name.ends_with("_RX"):
				axis_pair.type = AxisPair.TYPE.RIGHT_JOY
				axis_pair.x_axis = event
			elif code_name.ends_with("_RY"):
				axis_pair.type = AxisPair.TYPE.RIGHT_JOY
				axis_pair.y_axis = event
			elif code_name.ends_with("_Z"):
				axis_pair.type = AxisPair.TYPE.TRIGGER
				axis_pair.x_axis = event
			elif code_name.ends_with("_RZ"):
				axis_pair.type = AxisPair.TYPE.TRIGGER
				axis_pair.y_axis = event
			elif code_name.ends_with("_HAT0X"):
				axis_pair.type = AxisPair.TYPE.HAT0
				axis_pair.x_axis = event
			elif code_name.ends_with("_HAT0Y"):
				axis_pair.type = AxisPair.TYPE.HAT0
				axis_pair.y_axis = event

			axes_events.append(axis_pair)
	
	# Create all the button mappings 
	for event in button_events:
		var label := $%ButtonsLabel
		_add_button_for_event(event, label)
	for axis_pair in axes_events.pairs:
		var label := $%AxesLabel
		_add_container_for_axis_pair(axis_pair, label)
		

## Create a card mapping button for the given event under the given parent
func _add_button_for_event(event: EvdevEvent, parent: Node) -> CardMappingButton:
	var idx := parent.get_index() + 1

	var button := button_scene.instantiate() as CardMappingButton
	button.text = "-"
	button.set_mapping.call_deferred([event] as Array[MappableEvent])

	# Add the button to our button map
	buttons[event.get_signature()] = button

	# Create a gamepad profile mapping when pressed
	var on_pressed := func():
		var mapping := GamepadMapping.new()
		mapping.source_event = event
		change_input_state.set_meta("texture", button.texture.texture)
		change_input_state.set_meta("mappings", [mapping] as Array[GamepadMapping])
		change_input_state.set_meta("output_index", 0)
		state_machine.push_state(change_input_state)
	button.button_up.connect(on_pressed)

	container.add_child(button)
	container.move_child(button, idx)
	return button


## Create buttons for axis pairs
func _add_container_for_axis_pair(pair: AxisPair, parent: Node) -> CardAxesMappingContainer:
	var idx := parent.get_parent().get_child_count()
	var axes_container := axes_container_scene.instantiate() as CardAxesMappingContainer
	var mode := axes_container.MODE.JOYSTICK

	# Add the container to our container list
	axes_containers.append(axes_container)

	# Handle trigger types
	if pair.type == pair.TYPE.TRIGGER:
		mode = axes_container.MODE.AXIS

	axes_container.set_mapping([pair.x_axis, pair.y_axis] as Array[MappableEvent])
	axes_container.set_mode.call_deferred(mode)
	container.add_child(axes_container)
	container.move_child(axes_container, idx)
	_set_axis_container_focus.call_deferred(axes_container)

	return axes_container


## Set the focus group
func _set_axis_container_focus(axes_container: Control) -> void:
	var new_focus_group := axes_container.get_node("FocusGroup") as FocusGroup
	previous_axis_focus_group.focus_neighbor_bottom = new_focus_group
	new_focus_group.focus_neighbor_top = previous_axis_focus_group
	previous_axis_focus_group = new_focus_group


# Syncs the UI to the given profile
func _load_profile_ui() -> void:
	if not profile:
		return
	profile_label.text = profile.name

	# Reset the button text
	for button in buttons.values():
		button.text = "-"

	# Set the button text based on the loaded profile
	for mapping in profile.mapping:
		var source_event := mapping.source_event
		var all_buttons := [buttons] as Array[Dictionary]
		for axes_container in axes_containers:
			all_buttons.append(axes_container.buttons)
		for buttons_dict in all_buttons:
			if not source_event.get_signature() in buttons_dict:
				continue
			var button := buttons_dict[source_event.get_signature()] as CardMappingButton

			# Set the text depending on the kind of output event
			var mapped_text := PackedStringArray()
			for event in mapping.output_events:
				var text := _get_display_string_for(event)
				mapped_text.append(text)
			button.text = " + ".join(mapped_text)


## Get the text to display on the mapping button from the given event
func _get_display_string_for(event: MappableEvent) -> String:
	if event is NativeEvent:
		var native_event := event as NativeEvent
		if native_event.event is InputEventKey:
			var key_event := native_event.event as InputEventKey
			return key_event.as_text()
		if native_event.event is InputEventMouseMotion:
			return "Mouse motion"
		if native_event.event is InputEventMouseButton:
			var mouse_event := native_event.event as InputEventMouseButton
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				return "Left mouse click"
			if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
				return "Middle mouse click"
			if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
				return "Right mouse click"
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				return "Mouse wheel up"
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				return "Mouse wheel down"
	if event is EvdevEvent:
		return ControllerMapper.get_joypad_path_from_event(event)

	return ""


# Save the current profile to a file
func _save_profile() -> void:
	var notify := Notification.new("")
	if not profile:
		logger.debug("No profile loaded to save")
		return
	if not library_item:
		# TODO: Fix typo v
		# TODO: Fix for gloabl
		logger.debug("No library item loaded to associate profile with")
		return

	# Try to save the profile
	if DirAccess.make_dir_recursive_absolute(user_profiles) != OK:
		logger.debug("Unable to create gamepad profiles directory")
		notify.text = "Unable to save gamepad profile"
		notification_manager.show(notify)
		return
	var filename := library_item.name.sha256_text() + ".tres"
	var path := "/".join([user_profiles, filename])
	if ResourceSaver.save(profile, path) != OK:
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
func _load_profile(profile_path: String = "") -> GamepadProfile:
	var loaded: GamepadProfile
	if profile_path == "" or not FileAccess.file_exists(profile_path):
		loaded = load(gamepad_manager.default_profile)
		if not loaded:
			loaded = GamepadProfile.new()
		else:
			loaded = loaded.duplicate(true)
		if library_item:
			loaded.name = library_item.name
		return loaded

	loaded = load(profile_path) as GamepadProfile
	return loaded


## Container for ABS axis mappings
class AxisPair:
	enum TYPE {
		LEFT_JOY,
		RIGHT_JOY,
		TRIGGER,
		HAT0,
	}

	var type: TYPE
	var x_axis: MappableEvent
	var y_axis: MappableEvent


## Structure for an array of axes
class AxesArray:
	var pairs: Array[AxisPair]

	func append(axis: AxisPair) -> void:
		for pair in pairs:
			if axis.type != pair.type:
				continue
			if axis.x_axis:
				pair.x_axis = axis.x_axis
			if axis.y_axis:
				pair.y_axis = axis.y_axis
			return
		
		# No match was found
		pairs.append(axis)

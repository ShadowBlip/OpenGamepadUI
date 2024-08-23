extends Control

const USER_TEMPLATES := "user://data/gamepad/templates"
const USER_PROFILES := "user://data/gamepad/profiles"
const GLOBAL_PROFILE_PATH := "user://data/gamepad/profiles/global.json"

var change_input_state := preload("res://assets/state/states/gamepad_change_input.tres") as State
var gamepad_state := load("res://assets/state/states/gamepad_settings.tres") as State
var in_game_state := load("res://assets/state/states/in_game.tres") as State
var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var global_state_machine := load("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var state_machine := load("res://assets/state/state_machines/gamepad_settings_state_machine.tres") as StateMachine
var input_plumber := load("res://core/systems/input/input_plumber.tres") as InputPlumber
var input_icons := load("res://core/systems/input/input_icon_manager.tres") as InputIconManager
var button_scene := load("res://core/ui/components/card_mapping_button.tscn") as PackedScene
var container_scene := load("res://core/ui/components/card_mapping_button_group.tscn") as PackedScene
var expandable_scene := load("res://core/ui/card_ui/quick_bar/qb_card.tscn") as PackedScene

var gamepad: InputPlumber.CompositeDevice
var profile: InputPlumberProfile
var profile_gamepad: String
var library_item: LibraryItem
var gamepad_types := ["Xbox 360", "XBox One Elite", "DualSense Edge", "Steam Deck (experimental)"]
var gamepad_types_icons := ["XBox 360", "Xbox One", "PS5", "Steam Deck"] #From res://assets/gamepad/icon_mappings
var gamepad_type_selected := 0
var mapping_elements: Dictionary = {}
var logger := Log.get_logger("GamepadSettings", Log.LEVEL.INFO)

@onready var in_game_panel := $%InGamePanel as Control
@onready var gamepad_label := $%GamepadLabel as Label
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
		_update_mapping_elements()
	delete_button.button_up.connect(on_delete)

	# Setup the gamepad type dropdown
	gamepad_type_dropdown.clear()
	for gamepad_type: String in self.gamepad_types:
		gamepad_type_dropdown.add_item(gamepad_type)
	var on_gamepad_selected := func(item_selected: int):
		self.gamepad_type_selected = item_selected
		if self.profile:
			var gamepad_type := self.get_selected_target_gamepad()
			profile_gamepad = InputPlumberProfile.get_target_device_string(gamepad_type)
			logger.debug("Setting gamepad to " + profile_gamepad)
		else:
			logger.debug("No profile, unable to set gamepad type.")
		self._update_mapping_elements()
	gamepad_type_dropdown.item_selected.connect(on_gamepad_selected)

	# Load the default profile
	var profile_path = settings_manager.get_value("input", "gamepad_profile", "")
	profile_gamepad = settings_manager.get_value("input", "gamepad_profile_target", "")
	for gamepad in input_plumber.composite_devices:
			_set_gamepad_profile(gamepad, profile_path)

	# Grab focus when the mapper exits
	var on_state_changed := func(_from: State, to: State):
		if to:
			return
		mapping_focus_group.grab_focus()
	state_machine.state_changed.connect(on_state_changed)

	# Ensure new devices are set to the correct profile when added
	input_plumber.composite_device_added.connect(_set_gamepad_profile)
	input_plumber.composite_device_changed.connect(_set_gamepad_profile)


## Called when the gamepad settings state is entered
func _on_state_entered(_from: State) -> void:
	# If the in-game state exists in the stack, display a background
	in_game_panel.visible = global_state_machine.has_state(in_game_state)
	
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

	logger.debug("Configuring gamepad '" + gamepad.name + "': " + dbus_path)
	
	# Set the gamepad name label
	gamepad_label.text = gamepad.name
	
	# Populate the menu with the source inputs for the given gamepad
	populate_mappings_for(gamepad)

	# Set the library item, if one exists
	library_item = null
	profile = null
	if gamepad_state.has_meta("item"):
		library_item = gamepad_state.get_meta("item") as LibraryItem

	# If no library item was set, but there's a running app, try to see if
	# there is a library item for it instead.
	if not library_item:
		library_item = launch_manager.get_current_app_library_item()

	# If no library item was set with the state, then configure the OGUI profile
	if not library_item:
		profile_label.text = "Global"
		@warning_ignore("confusable_local_declaration")
		var profile_path := settings_manager.get_value("input", "gamepad_profile", InputPlumber.DEFAULT_GLOBAL_PROFILE) as String
		var profile_target_gamepad := settings_manager.get_value("input", "gamepad_profile_target", "") as String
		profile = _load_profile(profile_path)
		profile_gamepad = profile_target_gamepad
		_update_mapping_elements()
		return

	# Set the profile text to the game name
	profile_label.text = library_item.name


	# Check to see if the given game has a gamepad profile
	var profile_path := settings_manager.get_library_value(library_item, "gamepad_profile", "") as String
	var profile_target_gamepad := settings_manager.get_library_value(library_item, "gamepad_profile_target", "") as String
	profile = _load_profile(profile_path)
	profile_gamepad = profile_target_gamepad
	_update_mapping_elements()
	
	# Clear focus
	mapping_focus_group.current_focus = null


func _on_state_exited(_to: State) -> void:
	# Delete any old buttons
	for child in container.get_children():
		if child is CardMappingButton:
			child.queue_free()
		if child is QuickBarCard:
			child.queue_free()

	# Ensure CompositeDevice references are dropped
	self.gamepad = null
	change_input_state.remove_meta("gamepad")

	# Clear the gamepad settings state
	gamepad_state.remove_meta("item")

	# Clear the focus state
	mapping_focus_group.current_focus = null
	mapping_focus_group.focus_stack.clear()

	# Save the profile (if one exists)
	if not self.profile:
		return
	_save_profile()


## Populates the button mappings for the given gamepad
func populate_mappings_for(gamepad: InputPlumber.CompositeDevice) -> void:
	var gamepad_name := gamepad.name
	var capabilities := gamepad.capabilities
	
	# Sort the capabilities
	capabilities = InputPlumberEvent.sort_capabilities(capabilities)
	capabilities.reverse()
	logger.debug("Found capabilities for gamepad: " + str(capabilities))

	# Delete any old UI elements
	for child in container.get_children():
		if child is CardMappingButton:
			child.queue_free()
		if child is CardMappingButtonGroup:
			child.queue_free()
	
	# Reset any focus group neighbors
	previous_axis_focus_group = mapping_focus_group 

	# Clear our UI mappings 
	mapping_elements = {}

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
			if not capability in button_events:
				button_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Axis"):
			if not capability in axes_events:
				axes_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Trigger"):
			if not capability in trigger_events:
				trigger_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Accelerometer"):
			if not capability in accel_events:
				accel_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Gyro"):
			if not capability in gyro_events:
				gyro_events.append(capability)
			continue
		if capability.begins_with("TouchPad:"):
			if not capability in touchpad_events:
				touchpad_events.append(capability)
			continue
		logger.warn("Unhandled capability: " + capability)
	
	# Create all the button mappings
	var label := $%ButtonsLabel
	label.visible = button_events.size() > 0
	for capability in button_events:
		_add_button_for_capability(gamepad_name, capability, label)

	label = $%AxesLabel
	label.visible = axes_events.size() > 0
	for capability in axes_events:
		_add_group_for_capability(gamepad_name, capability, label)

	label = $%TriggersLabel
	label.visible = trigger_events.size() > 0
	for capability in trigger_events:
		_add_button_for_capability(gamepad_name, capability, label)

	label = $%AccelerometerLabel
	label.visible = accel_events.size() > 0
	for capability in accel_events:
		_add_button_for_capability(gamepad_name, capability, label)

	label = $%GyroLabel
	label.visible = gyro_events.size() > 0
	for capability in gyro_events:
		_add_button_for_capability(gamepad_name, capability, label)

	label = $%TouchpadsLabel
	label.visible = touchpad_events.size() > 0
	for capability in touchpad_events:
		_add_button_for_capability(gamepad_name, capability, label)


## Create a card mapping button for the given event under the given parent
func _add_button_for_capability(gamepad_name: String, capability: String, parent: Node) -> CardMappingButton:
	var idx := parent.get_index() + 1

	var button := button_scene.instantiate() as CardMappingButton
	var on_button_ready := func():
		# Get the icon map name of the currently selected target gamepad. E.g.
		# if the PS5 target gamepad is selected, the button will show the
		# target input icon for the PS5 controller. 
		var icon_mapping := get_selected_target_gamepad_icon_map()
		button.set_target_device_icon_mapping(icon_mapping)
		button.set_target_capability(capability)

		# Get the icon map name from the source gamepad we're configuring.
		var source_mapping_name := input_icons.get_mapping_name_from_device(gamepad_name)
		button.set_source_device_icon_mapping(source_mapping_name)
		button.set_source_capability(capability)

	button.ready.connect(on_button_ready, CONNECT_ONE_SHOT)

	# Add the button to our button map
	mapping_elements[capability] = button

	# Create a gamepad profile mapping when pressed
	var on_pressed := func():
		# Create a new mapping for this button
		var mapping := InputPlumberMapping.from_source_capability(capability)
		if not mapping:
			logger.error("Failed to set source event with capability: " + capability)
			return
		
		# Switch to change_input_state with the selected mapping to be updated
		var texture: Texture
		if button.source_icon.textures.size() > 0:
			texture = button.source_icon.textures[0]
		change_input_state.set_meta("texture", texture)
		change_input_state.set_meta("mappings", mapping)
		change_input_state.set_meta("gamepad", self.gamepad)
		change_input_state.set_meta("gamepad_type", self.gamepad_types[self.gamepad_type_selected])
		change_input_state.set_meta("gamepad_type_icon_map", self.get_selected_target_gamepad_icon_map())
		state_machine.push_state(change_input_state)
	button.button_up.connect(on_pressed)

	# Add the button to the container and move it just under the given parent
	container.add_child(button)
	container.move_child(button, idx)

	return button


## Create a card mapping group for the given event under the given parent
func _add_group_for_capability(gamepad_name: String, capability: String, parent: Node) -> CardMappingButtonGroup:
	var idx := parent.get_index() + 1

	# Create an expandable card to put the group in
	var expandable_card := expandable_scene.instantiate() as QuickBarCard

	var mapping_group := container_scene.instantiate() as CardMappingButtonGroup
	mapping_group.set_source_capability(capability)
	var on_container_ready := func():
		# Get the icon map name of the currently selected target gamepad. E.g.
		# if the PS5 target gamepad is selected, the button will show the
		# target input icon for the PS5 controller. 
		var icon_mapping := get_selected_target_gamepad_icon_map()
		mapping_group.set_target_device_icon_mapping(icon_mapping)
		
		# Get the icon map name from the source gamepad we're configuring.
		var source_mapping_name := input_icons.get_mapping_name_from_device(gamepad_name)
		mapping_group.set_source_device_icon_mapping(source_mapping_name)
		mapping_group.set_source_capability(capability)

	mapping_group.ready.connect(on_container_ready, CONNECT_ONE_SHOT)

	# Add the element to our element map
	mapping_elements[capability] = mapping_group

	# Set a callback if any buttons in the group are pressed
	var on_pressed := func():
		change_input_state.set_meta("gamepad", self.gamepad)
		change_input_state.set_meta("gamepad_type", self.gamepad_types[self.gamepad_type_selected])
		change_input_state.set_meta("gamepad_type_icon_map", self.get_selected_target_gamepad_icon_map())
		state_machine.push_state(change_input_state)
	mapping_group.set_callback(on_pressed)

	# Add an input icon as the header of the card
	var input_icon := InputIcon.new()
	input_icon.max_width = 64
	var icon_path := InputPlumberEvent.get_joypad_path(capability)
	input_icon.path = icon_path
	var source_mapping_name := input_icons.get_mapping_name_from_device(gamepad_name)
	input_icon.force_mapping = source_mapping_name

	# Hide elements with no icon as they aren't yet supported in InputPlumber.
	var on_card_ready := func():
		if input_icon.textures.is_empty():
			logger.debug("No texture found, hiding " + capability + " expandable card.")
			expandable_card.visible = false
	input_icon.ready.connect(on_card_ready)

	# Add the group to the expandable card
	expandable_card.add_header(input_icon, BoxContainer.ALIGNMENT_BEGIN)
	expandable_card.add_content(mapping_group)

	# Add the button to the container and move it just under the given parent
	container.add_child(expandable_card)
	container.move_child(expandable_card, idx)

	return mapping_group


## Syncs the UI to the given profile
func _update_mapping_elements() -> void:
	if not profile:
		return
	profile_label.text = profile.name

	# Update the dropdown based on the profile's target gamepad type
	if not profile_gamepad.is_empty():
		var target_device := InputPlumberProfile.get_target_device(profile_gamepad)
		var gamepad_text := self.get_target_gamepad_text(target_device)
		var i := 0
		var idx := 0
		for item in self.gamepad_types:
			if item == gamepad_text:
				idx = i
				break
			i += 1
		gamepad_type_dropdown.select(idx)

	# Reset the button text
	for node in mapping_elements.values():
		if node is CardMappingButton:
			node.text = "-"

	var mapped_capabilities := profile.get_mappings_source_capabilities()
	for capability in mapping_elements:

		# Find if this capability was remapped
		var mappings : Array[InputPlumberMapping]
		if capability in mapped_capabilities:
			mappings = profile.get_mappings_by_source_capability(capability)
		else:
			var mapping := InputPlumberMapping.from_source_capability(capability)
			if not mapping:
				logger.error("Failed to create Mapping from Capability", capability)
				continue
			var target_event = InputPlumberEvent.from_capability(capability)
			logger.debug("Adding", capability, "to mappings as:", mapping, " with event:", target_event)
			mapping.target_events = [target_event]
			mappings = [mapping]

		# Find the UI element for this capability
		var element = mapping_elements[capability]

		# Update the button or container using the given mapping(s)
		if element is CardMappingButton:
			var button := element as CardMappingButton
			_update_button(button, mappings[0])
		elif element is CardMappingButtonGroup:
			var group := element as CardMappingButtonGroup
			var input_mappings: Array[InputPlumberMapping] = []
			input_mappings.assign(mappings)
			_update_button_group(group, input_mappings)


## Update the button's target icon using the given mapping. This will only be
## called if a mapping already exists in a profile.
func _update_button(button: CardMappingButton, mapping: InputPlumberMapping) -> void:
	button.text = ""

	# Configure no target icon if there is no target events
	if not mapping or mapping.target_events.is_empty():
		logger.warn("Mapping '" + mapping.name + "' has no target events")
		return
	
	# Get the target capability to determine if this is a gamepad icon or keyboard/mouse
	# TODO: Figure out what to do if this maps to multiple types of input (e.g. Keyboard + Gamepad)
	var target_capability := mapping.target_events[0].to_capability()
	var target_input_type := 2 # gamepad
	if target_capability.begins_with("Mouse") or target_capability.begins_with("Keyboard"):
		target_input_type = 1 # kb/mouse
	button.target_icon.force_type = target_input_type

	# Set the icon mapping to use
	if target_input_type == 1:
		logger.debug("Using keyboard/mouse icon mapping")
		button.set_target_device_icon_mapping("")
	else:
		var icon_mapping := get_selected_target_gamepad_icon_map()
		logger.debug("Using target icon mapping: " + icon_mapping)
		button.set_target_device_icon_mapping(icon_mapping)

	# Set the target capability
	for event in mapping.target_events:
		button.set_target_capability(event.to_capability())
		# TODO: Figure out what to display if this maps to multiple inputs
		break


## Update the given button group using the given mappings. Button groups are used
## for mappings that can have several entries (i.e. mapping LeftStick to W, A, S, D).
## This method will only be called if mappings already exist in the loaded profile.
func _update_button_group(group: CardMappingButtonGroup, mappings: Array[InputPlumberMapping]) -> void:
	# Determine what input type this capability is using. This can either
	# be Joystick or Button; E.g. used for mapping a joystick to buttons
	# or to another joystick/mouse.
	if mappings[0].source_event.get_direction().is_empty():
		group.set_mapping_type(CardMappingButtonGroup.MappingType.Joystick)
	else:
		group.set_mapping_type(CardMappingButtonGroup.MappingType.Button)

	# Assign the mappings to the group
	group.set_mappings(mappings)


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
		# Skip non-matching mappings
		if not mapping.source_event.matches(existing_mapping.source_event):
			continue

		# If this mapping doesn't have a direction, remove all existing
		# mappings and replace it with this one.
		if mapping.source_event.get_direction().is_empty():
			to_remove.append(existing_mapping)

		# If this mapping is part of a group of mappings, but mappings exist
		# that don't have a direction, remove them.
		var existing_direction := existing_mapping.source_event.get_direction()
		if existing_direction.is_empty():
			to_remove.append(existing_mapping)
			continue
		
		# If this mapping is part of a group of mappings, only remove the ones
		# that match the same direction
		var direction := mapping.source_event.get_direction()
		if direction == existing_direction:
			to_remove.append(existing_mapping)

	# Remove the existing mappings
	for map in to_remove:
		logger.debug("Removing old mapping: " + str(map))
		profile.mapping.erase(map)
	
	# Add the mapping to the profile
	logger.debug("Adding mapping: " + str(mapping))
	profile.mapping.append(mapping)

	logger.debug("Reloading profile")
	_update_mapping_elements()


## Returns the InputPlumber gamepad string based on the currently selected
## gamepad type in the dropdown
func get_selected_target_gamepad() -> InputPlumberProfile.TargetDevice:
	var selected_gamepad := self.gamepad_types[self.gamepad_type_selected] as String
	match selected_gamepad:
		"XBox 360":
			return InputPlumberProfile.TargetDevice.XBox360
		"XBox Series":
			return InputPlumberProfile.TargetDevice.XBoxSeries
		"XBox One Elite":
			return InputPlumberProfile.TargetDevice.XBoxElite
		"DualSense":
			return InputPlumberProfile.TargetDevice.DualSenseEdge
		"DualSense Edge":
			return InputPlumberProfile.TargetDevice.DualSenseEdge
		"Steam Deck (experimental)":
			return InputPlumberProfile.TargetDevice.SteamDeck
	logger.error(selected_gamepad + " not found. Using XBox360")
	return InputPlumberProfile.TargetDevice.XBox360


## Returns the name of the gamepad icon map to use for target capabilities
func get_selected_target_gamepad_icon_map() -> String:
	var selected_target_icon_map := self.gamepad_types_icons[self.gamepad_type_dropdown.selected] as String
	return selected_target_icon_map


## Returns the gamepad type text for the given InputPlumber gamepad string
func get_target_gamepad_text(gamepad_type: InputPlumberProfile.TargetDevice) -> String:
	match gamepad_type:
		InputPlumberProfile.TargetDevice.DualSense:
			return "DualSense"
		InputPlumberProfile.TargetDevice.DualSenseEdge:
			return "DualSense Edge"
		InputPlumberProfile.TargetDevice.SteamDeck:
			return "Steam Deck (experimental)"
		InputPlumberProfile.TargetDevice.XBox360:
			return "XBox 360"
		InputPlumberProfile.TargetDevice.XBoxSeries:
			return "XBox Series"
		InputPlumberProfile.TargetDevice.XBoxElite:
			return "XBox One Elite"
	
	logger.error("Gamepad Type: " + str(gamepad_type) + " not found. Using XBox360")
	return "XBox 360"


#  Set the given profile for the given composte device.
func _set_gamepad_profile(gamepad: InputPlumber.CompositeDevice, profile_path: String = "") -> void:
	if profile_path == "":
		if gamepad_state.has_meta("item"):
			library_item = gamepad_state.get_meta("item") as LibraryItem

		# If no library item was set, but there's a running app, try to see if
		# there is a library item for it instead.
		if not library_item:
			library_item = launch_manager.get_current_app_library_item()

		# If no library item was set with the state, then use the default
		if not library_item:
			profile_path = settings_manager.get_value("input", "gamepad_profile", "") as String
		else:
			profile_path = settings_manager.get_library_value(library_item, "gamepad_profile", "")

	logger.debug("Setting " + gamepad.name + " to profile: " + profile_path)
	gamepad.target_modify_profile(profile_path, profile_gamepad)

	# Set the target gamepad if one was specified
	if not profile_gamepad.is_empty():
		var target_devices := [profile_gamepad, "keyboard", "mouse"]
		match profile_gamepad:
			"xb360", "xbox-series", "xbox-elite", "gamepad":
				target_devices.append("touchpad")
			_:
				logger.debug(profile_gamepad, "needs no additional target devices.")
		logger.debug("Setting target devices to: ", target_devices)
		gamepad.set_target_devices(target_devices)

# Save the current profile to a file
func _save_profile() -> void:
	var notify := Notification.new("")
	if not profile:
		logger.debug("No profile loaded to save")
		return

	# Handle global gamepad profiles
	if not library_item:
		logger.debug("No library item loaded to associate profile with")
		# Save the profile
		@warning_ignore("confusable_local_declaration")
		var path := GLOBAL_PROFILE_PATH
		if profile.save(path) != OK:
			logger.error("Failed to save global gamepad profile to: " + path)
			notify.text = "Failed to save global gamepad profile"
			notification_manager.show(notify)
			return

		# Update the game settings to use this global profile
		settings_manager.set_value("input", "gamepad_profile", path)
		settings_manager.set_value("input", "gamepad_profile_target", profile_gamepad)

		for gamepad in input_plumber.composite_devices:
			_set_gamepad_profile(gamepad, path)

		logger.debug("Saved global gamepad profile to: " + path)
		notify.text = "Global gamepad profile saved"
		notification_manager.show(notify)
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
	settings_manager.set_value(section, "gamepad_profile_target", profile_gamepad)
	logger.debug("Saved gamepad profile to: " + path)
	notify.text = "Gamepad profile saved"
	notification_manager.show(notify)

	# Update/reload the saved profile
	#profile = ResourceLoader.load(path, "GamepadProfile", ResourceLoader.CACHE_MODE_IGNORE)
	var running_app := launch_manager.get_current_app()
	if running_app:
		if running_app.launch_item.name != library_item.name:
			pass
		logger.warn("Reloading gamepad profile for running game")
		launch_manager.set_gamepad_profile(path)


# Load the given gamepad profile. Returns the default gamepad profile if the 
# given profile does not exist.
func _load_profile(profile_path: String = "") -> InputPlumberProfile:
	var loaded: InputPlumberProfile
	if profile_path == "" or not profile_path.ends_with(".json") or not FileAccess.file_exists(profile_path):
		loaded = InputPlumberProfile.load(InputPlumber.DEFAULT_GLOBAL_PROFILE)
		if not loaded:
			loaded = InputPlumberProfile.new()
		if library_item:
			loaded.name = library_item.name
		return loaded

	loaded = InputPlumberProfile.load(profile_path)

	return loaded

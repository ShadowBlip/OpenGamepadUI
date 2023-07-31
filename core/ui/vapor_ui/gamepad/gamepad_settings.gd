extends Control

const SettingsManager := preload("res://core/global/settings_manager.tres")
const NotificationManager := preload("res://core/global/notification_manager.tres")
const LaunchManager := preload("res://core/global/launch_manager.tres")

var state_machine := load("res://assets/state/state_machines/gamepad_settings_state_machine.tres") as StateMachine

const user_templates := "user://data/gamepad/templates"
const user_profiles := "user://data/gamepad/profiles"

var gamepad_settings_state := preload("res://assets/state/states/gamepad_settings.tres") as State
var change_input_state := preload("res://assets/state/states/gamepad_change_input.tres") as State
var library_item: LibraryItem
var profile: GamepadProfile
var last_focus: Control
var logger := Log.get_logger("GamepadSettings", Log.LEVEL.INFO)

@onready var focus_node: Control = $%NewButton

@onready var profile_label := $%ProfileNameLabel as Label
@onready var new_button := $%NewButton as CardButton
@onready var delete_button := $%DeleteButton as Button
@onready var mapping_nodes := get_tree().get_nodes_in_group("gamepad_mapping")
@onready var gamepad_mapper := $%GamepadMapper


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	last_focus = focus_node
	gamepad_settings_state.state_entered.connect(_on_state_entered)
	gamepad_settings_state.state_exited.connect(_on_state_exited)
	new_button.pressed.connect(_create_profile)
	delete_button.pressed.connect(_clear_profile)

	# Connect all mapping buttons to the open mapping window method
	for node in mapping_nodes:
		var button := node as Button
		button.pressed.connect(_open_mapping_window.bind(button))
		var on_focus := func():
			last_focus = button
		button.focus_entered.connect(on_focus)

	# Grab focus if we have no more child states 
	var on_state_changed := func(_from: State, _to: State):
		if state_machine.stack_length() == 0:
			last_focus.grab_focus.call_deferred()
	state_machine.state_changed.connect(on_state_changed)

	# Listen to see if a mapping was selected 
	var on_mapping_selected := func(mapping: GamepadMapping):
		pass
#		var source_event := mapping.get_source_event_name()
#		# Remove old mappings
#		var to_remove := []
#		for m in profile.mapping:
#			# TODO: Handle cases where ABS events are specified. 
#			# We could have from 2-4 of these
#			if source_event.begins_with("ABS"):
#				continue
#			if m.get_source_event_name() == source_event:
#				to_remove.append(m)
#		for m in to_remove:
#			logger.debug("Removing old mapping: " + str(m.target))
#			profile.mapping.erase(m)
#		logger.debug("Adding mapping: " + mapping.get_source_event_name())
#		profile.mapping.append(mapping)
#		logger.debug("Reloading profile")
#		_load_profile()
	gamepad_mapper.mapping_selected.connect(on_mapping_selected)


func _on_state_entered(_from: State) -> void:
	# Focus the first entry on state change
	focus_node.grab_focus.call_deferred()

	# Clear all the current mappings
	_clear_mappings()

	# Disable all mappings unless we load or create a new profile
	_set_enable_mappings(false)

	library_item = null
	profile = null
	if "item" in gamepad_settings_state.data:
		library_item = gamepad_settings_state.data["item"] as LibraryItem

	# If no library item was set with the state, we can't do much
	if not library_item:
		profile_label.text = "No game selected"
		return

	# Check to see if the given game has a gamepad profile
	var section := "game.{0}".format([library_item.name.to_lower()])
	var profile_path := SettingsManager.get_value(section, "gamepad_profile", "") as String
	if profile_path == "":
		profile_label.text = "No profile"
		return

	# If the profile exists, load er' up
	_load_profile_from_file(profile_path)


func _on_state_exited(_to: State) -> void:
	if profile and library_item:
		_save_profile()
	library_item = null
	profile = null


# Opens the mapping window when a button is selected
func _open_mapping_window(button: Button) -> void:
	# Get the texture icon the button used
	var input_texture := button.icon
	gamepad_mapper.input_texture = input_texture

	# Create a new mapping item based on the button name and provide it
	# to the mapping window
	var mapping := GamepadMapping.new()
	var event_name := button.name
	if event_name.ends_with("_POSITIVE"):
		event_name = event_name.replace("_POSITIVE", "")
		mapping.axis = mapping.AXIS.POSITIVE
	if event_name.ends_with("_NEGATIVE"):
		event_name = event_name.replace("_NEGATIVE", "")
		mapping.axis = mapping.AXIS.NEGATIVE
	mapping.set_source_event(event_name)
	gamepad_mapper.mapping = mapping

	state_machine.push_state(change_input_state)


# Enables/Disables all mapping buttons
func _set_enable_mappings(enabled: bool) -> void:
	for node in mapping_nodes:
		var button := node as Button
		button.disabled = !enabled


# Sets all of the Button nodes to have empty text
func _clear_mappings() -> void:
	# Reset all mappings
	for node in mapping_nodes:
		var button := node as Button
		button.text = "-"


# Removes the current profile from the current library item
func _clear_profile() -> void:
	if not library_item:
		logger.debug("No library item to clear gamepad profile")
		return
	profile = null
	_clear_mappings()
	_set_enable_mappings(false)
	var section := "game.{0}".format([library_item.name.to_lower()])
	SettingsManager.erase_section_key(section, "gamepad_profile")
	profile_label.text = "No profile"


# Load the given gamepad profile and update the UI
func _load_profile_from_file(profile_path: String) -> void:
	# Try to load the profile
	if not FileAccess.file_exists(profile_path):
		var notify := Notification.new("Profile not found: " + profile_path)
		NotificationManager.show(notify)
		profile_label.text = "No profile"
		return

	profile = load(profile_path) as GamepadProfile
	_load_profile()


# Syncs the UI to the given profile
func _load_profile() -> void:
	if not profile:
		_set_enable_mappings(false)
		_clear_mappings()
		profile_label.text = "No profile"
		return

	profile_label.text = profile.name
	_set_enable_mappings(true)

	# Reset all mappings
	_clear_mappings()

	# Loop through all mappings and update each UI component
	for m in profile.mapping:
		var mapping := m as GamepadMapping

		# Get the name of the source event. We use this name to derive
		# the name of the Control node to update
		var event_name := mapping.SOURCE_EVENTS[mapping.source] as String
		var node_names := [event_name]
		var buttons: Array[Button] = []

		# Check if the mapping is only for a positive/negative axis.
		# If it is, update our node name with the suffix
		if mapping.axis == mapping.AXIS.POSITIVE:
			node_names[0] += "_POSITIVE"
		if mapping.axis == mapping.AXIS.NEGATIVE:
			node_names[0] += "_NEGATIVE"
		if mapping.axis == mapping.AXIS.BOTH:
			node_names.append(node_names[0] + "_POSITIVE")
			node_names.append(node_names[0] + "_NEGATIVE")

		# Get the Control node(s) for this specific mapping
		for node_name in node_names:
			var button := get_node_or_null("%" + node_name) as Button
			if not button:
				logger.debug("No node found with unique name: " + node_name)
				continue
			buttons.append(button)

		# Update the button(s) based on what the mapping should be
		for button in buttons:
			if mapping.target is InputEventKey:
				var key_name := OS.get_keycode_string(mapping.target.keycode)
				button.text = key_name
				continue

			if mapping.target is InputEventMouseMotion:
				button.text = "Mouse Motion"

			if mapping.target is InputEventMouseButton:
				match mapping.target.button_index:
					MOUSE_BUTTON_LEFT:
						button.text = "Mouse Left Click"
					MOUSE_BUTTON_MIDDLE:
						button.text = "Mouse Middle Click"
					MOUSE_BUTTON_RIGHT:
						button.text = "Mouse Right Click"
					MOUSE_BUTTON_WHEEL_UP:
						button.text = "Mouse Wheel Up"
					MOUSE_BUTTON_WHEEL_DOWN:
						button.text = "Mouse Wheel Down"


# Save the current profile to a file
func _save_profile() -> void:
	if not profile:
		logger.debug("No profile loaded to save")
		return
	if not library_item:
		logger.debug("No library item loaded to associate profile with")
		return

	# Try to save the profile
	if DirAccess.make_dir_recursive_absolute(user_profiles) != OK:
		logger.debug("Unable to create gamepad profiles directory")
		return
	var filename := library_item.name.sha256_text() + ".tres"
	var path := "/".join([user_profiles, filename])
	if ResourceSaver.save(profile, path) != OK:
		logger.error("Failed to save gamepad profile to: " + path)
		return

	# Update the game settings to use this gamepad profile
	var section := "game.{0}".format([library_item.name.to_lower()])
	SettingsManager.set_value(section, "gamepad_profile", path)
	logger.debug("Saved gamepad profile to: " + path)

	# Update/reload the saved profile
	#profile = ResourceLoader.load(path, "GamepadProfile", ResourceLoader.CACHE_MODE_IGNORE)
	var running_app := LaunchManager.get_current_app()
	if running_app:
		if running_app.launch_item.name != library_item.name:
			pass
		logger.debug("Reloading gamepad profile for running game")
		LaunchManager.set_gamepad_profile(path)


# Creates a new empty gamepad profile for the current library item
func _create_profile() -> void:
	if not library_item:
		logger.debug("No library item loaded to create profile for")
		return
	profile = GamepadProfile.new()
	profile.name = library_item.name
	profile_label.text = profile.name
	_set_enable_mappings(true)

extends Control

const SettingsManager := preload("res://core/global/settings_manager.tres")
const NotificationManager := preload("res://core/global/notification_manager.tres")

var gamepad_settings_state := preload("res://assets/state/states/gamepad_settings.tres") as State
var library_item: LibraryItem
var profile: GamepadProfile
var logger := Log.get_logger("GamepadSettings")

@export var focus_node: Control

@onready var profile_label := $%ProfileNameLabel as Label
@onready var diagram := $%DiagramTextureRect as TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gamepad_settings_state.state_entered.connect(_on_state_entered)
	gamepad_settings_state.state_exited.connect(_on_state_exited)


func _on_state_entered(_from: State) -> void:
	# Focus the first entry on state change
	focus_node.grab_focus.call_deferred()

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
	_load_profile(profile_path)


func _on_state_exited(_to: State) -> void:
	library_item = null
	profile = null


# Updates the center controller diagram with the appropriate texture
func _update_diagram() -> void:
	var mapper := ControllerMapper.new()
	var fallback := ControllerSettings.Devices.XBOX360
	var gamepad_type := mapper._get_joypad_type(fallback) as ControllerSettings.Devices
	match gamepad_type:
		ControllerSettings.Devices.XBOX360:
			diagram.texture = load("res://assets/images/gamepad/xbox360/XboxOne_Diagram.png")
			return

	# Fallback if we have no diagram
	diagram.texture = load("res://assets/images/gamepad/xbox360/XboxOne_Diagram.png")


# Load the given gamepad profile and update the UI
func _load_profile(profile_path: String) -> void:
	# Try to load the profile
	if not FileAccess.file_exists(profile_path):
		var notify := Notification.new("Profile not found: " + profile_path)
		NotificationManager.show(notify)
		profile_label.text = "No profile"
		return

	profile = load(profile_path) as GamepadProfile
	profile_label.text = profile.name

	# Reset all mappings
	var mapping_nodes := get_tree().get_nodes_in_group("gamepad_mapping")
	for node in mapping_nodes:
		var button := node as Button
		button.text = "-"

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

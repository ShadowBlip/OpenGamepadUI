extends Control

var gamepad_manager := load("res://core/systems/input/gamepad_manager.tres") as GamepadManager
var gamepad_state := load("res://assets/state/states/gamepad_settings.tres") as State

var button_scene := load("res://core/ui/components/card_mapping_button.tscn") as PackedScene

@onready var container := $%ButtonMappingContainer as Container


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gamepad_state.state_entered.connect(_on_state_entered)


## Called when the gamepad settings state is entered
func _on_state_entered(_from: State) -> void:
	var gamepads := gamepad_manager.get_gamepad_paths()
	# TODO: Configure the menu per-gamepad to support multiple gamepads
	if gamepads.size() == 0:
		return
	populate_mappings_for(gamepads[0])


func get_gamepad_capabilities() -> void:
	var gamepads := gamepad_manager.get_gamepad_paths()
	print("Gamepads: ", gamepads)
	
	# TODO: Configure the menu per-gamepad to support multiple gamepads
	if gamepads.size() == 0:
		return
	
	var capabilities := gamepad_manager.get_gamepad_capabilities(gamepads[0])
	print("Got capabilities: ", capabilities)


## Populates the button mappings for the given gamepad
func populate_mappings_for(gamepad_path: String) -> void:
	var capabilities := gamepad_manager.get_gamepad_capabilities(gamepad_path)

	# Delete any old buttons
	for child in container.get_children():
		if child is CardMappingButton:
			child.queue_free()
	
	# Organize all the capabilities
	var button_events: Array[EvdevKeyEvent] = []
	var key_events: Array[EvdevKeyEvent] = []
	var joystick_events: Array[EvdevAbsEvent] = []
	var trigger_events: Array[EvdevAbsEvent] = []
	for event in capabilities:
		if event is EvdevKeyEvent:
			var code_name := event.to_input_device_event().get_code_name() as String
			if code_name.begins_with("BTN"):
				button_events.append(event)
				continue
			key_events.append(event)
			continue
		elif event is EvdevAbsEvent:
			var lt := InputDeviceEvent.ABS_Z
			var rt := InputDeviceEvent.ABS_RZ
			if event.get_event_code() in [lt, rt]:
				trigger_events.append(event)
				continue
			joystick_events.append(event)
			continue
	
	# Create all the button mappings 
	for event in button_events:
		var label := $%ButtonsLabel
		_add_button_for_event(event, label)
	for event in joystick_events:
		var label := $%JoysticksLabel
		_add_button_for_event(event, label)
	for event in trigger_events:
		var label := $%TriggersLabel
		_add_button_for_event(event, label)
		

## Create a card mapping button for the given event under the given parent
func _add_button_for_event(event: EvdevEvent, parent: Node) -> void:
	var idx := parent.get_index() + 1

	var button := button_scene.instantiate() as CardMappingButton
	button.text = "-"
	button.set_mapping.call_deferred(event)

	container.add_child(button)
	container.move_child(button, idx)

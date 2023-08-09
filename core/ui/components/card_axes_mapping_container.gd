extends VBoxContainer
class_name CardAxesMappingContainer

enum MODE {
	JOYSTICK,
	AXIS,
	BUTTON,
}

var state_machine := load("res://assets/state/state_machines/gamepad_settings_state_machine.tres") as StateMachine
var change_input_state := preload("res://assets/state/states/gamepad_change_input.tres") as State
var button_scene := load("res://core/ui/components/card_mapping_button.tscn") as PackedScene
var pairs: Array[MappableEvent]
var buttons: Dictionary = {}

@onready var dropdown := $%Dropdown as Dropdown


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dropdown.clear()
	dropdown.add_item("Joystick Mode")
	dropdown.add_item("Axis Mode")
	dropdown.add_item("Button Mode")
	dropdown.item_selected.connect(_on_selected)


func set_mapping(events: Array[MappableEvent]) -> void:
	pairs = events


func set_mode(mode: MODE) -> void:
	dropdown.select(mode)
	_on_selected(mode)


func _clear_buttons() -> void:
	# Delete any old buttons
	for child in get_children():
		if child is CardMappingButton:
			child.queue_free()
	buttons = {}


func _on_selected(value: int) -> void:
	if value == MODE.JOYSTICK:
		_on_joystick_mode_selected()
	elif value == MODE.AXIS:
		_on_axis_mode_selected()
	elif value == MODE.BUTTON:
		_on_button_mode_selected()


func _on_joystick_mode_selected() -> void:
	_clear_buttons()
	if pairs.size() != 2:
		return

	var button := button_scene.instantiate() as CardMappingButton
	button.text = "-"
	button.set_mapping.call_deferred(pairs)

	var mapping1 := GamepadMapping.new()
	mapping1.source_event = pairs[0]
	mapping1.output_events.resize(1)
	mapping1.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.SEQUENCE
	var mapping2 := GamepadMapping.new()
	mapping2.source_event = pairs[1]
	mapping2.output_events.resize(1)
	mapping2.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.SEQUENCE

	button.set_meta("mappings", [mapping1, mapping2] as Array[GamepadMapping])
	button.button_up.connect(_on_button_pressed.bind(button))
	add_child(button)

	buttons[pairs[0].get_signature()] = button


func _on_axis_mode_selected() -> void:
	_clear_buttons()
	if pairs.size() != 2:
		return

	var left_button := button_scene.instantiate() as CardMappingButton
	left_button.text = "-"
	left_button.set_mapping.call_deferred([pairs[0]] as Array[MappableEvent])

	var left_mapping := GamepadMapping.new()
	left_mapping.source_event = pairs[0]
	left_mapping.output_events.resize(2)
	left_mapping.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.SEQUENCE
	left_button.set_meta("mappings", [left_mapping] as Array[GamepadMapping])
	left_button.button_up.connect(_on_button_pressed.bind(left_button))
	add_child(left_button)
	buttons[pairs[0].get_signature()] = left_button

	var right_button := button_scene.instantiate() as CardMappingButton
	right_button.text = "-"
	right_button.set_mapping.call_deferred([pairs[1]] as Array[MappableEvent])

	var right_mapping := GamepadMapping.new()
	right_mapping.source_event = pairs[1]
	right_mapping.output_events.resize(2)
	right_mapping.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.SEQUENCE
	right_button.set_meta("mappings", [right_mapping] as Array[GamepadMapping])
	right_button.button_up.connect(_on_button_pressed.bind(right_button))
	add_child(right_button)
	buttons[pairs[1].get_signature()] = right_button


func _on_button_mode_selected() -> void:
	_clear_buttons()
	if pairs.size() != 2:
		return

	var mapping1 := GamepadMapping.new()
	mapping1.source_event = pairs[0]
	mapping1.output_events.resize(2)
	mapping1.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.AXIS
	var mapping2 := GamepadMapping.new()
	mapping2.source_event = pairs[1]
	mapping2.output_events.resize(2)
	mapping2.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.AXIS

	for i in range(4):
		var button := button_scene.instantiate() as CardMappingButton
		button.text = "-"
		if i == 0:
			button.set_mapping.call_deferred([pairs[0]] as Array[MappableEvent])
			button.set_meta("output_index", 0)
			button.set_meta("mappings", [mapping1] as Array[GamepadMapping])
			buttons[pairs[0].get_signature()] = button
		if i == 1:
			button.set_mapping.call_deferred([pairs[0]] as Array[MappableEvent])
			button.set_meta("output_index", 1)
			button.set_meta("mappings", [mapping1] as Array[GamepadMapping])
		if i == 2:
			button.set_mapping.call_deferred([pairs[1]] as Array[MappableEvent])
			button.set_meta("output_index", 0)
			button.set_meta("mappings", [mapping2] as Array[GamepadMapping])
			buttons[pairs[1].get_signature()] = button
		if i == 3:
			button.set_mapping.call_deferred([pairs[1]] as Array[MappableEvent])
			button.set_meta("output_index", 1)
			button.set_meta("mappings", [mapping2] as Array[GamepadMapping])
		button.button_up.connect(_on_button_pressed.bind(button))
		add_child(button)


# Create a gamepad profile mapping when pressed
func _on_button_pressed(button: CardMappingButton) -> void:
	var mappings := button.get_meta("mappings") as Array[GamepadMapping]
	change_input_state.set_meta("texture", button.texture.texture)
	change_input_state.set_meta("mappings", mappings)
	change_input_state.set_meta("output_index", 0)
	if button.has_meta("output_index"):
		change_input_state.set_meta("output_index", button.get_meta("output_index"))
	state_machine.push_state(change_input_state)

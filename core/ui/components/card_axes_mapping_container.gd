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
var axes_mapping := GamepadAxesMapping.new()
var buttons: Dictionary = {}

@onready var dropdown := $%Dropdown as Dropdown


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	dropdown.clear()
	dropdown.add_item("Joystick/Mouse")
	dropdown.add_item("Independent Axes")
	dropdown.add_item("Buttons")
	dropdown.item_selected.connect(_on_selected)

func set_mapping(events: Array[MappableEvent]) -> void:
	pairs = events


func set_mode(mode: MODE) -> void:
	dropdown.select(mode)
	_on_selected(mode)


func determine_mode(profile: GamepadProfile) -> MODE:
	if pairs.size() != 2:
		return MODE.JOYSTICK

	var mapping_x := profile.get_mapping_for(pairs[0])
	var mapping_y := profile.get_mapping_for(pairs[1])

	if mapping_x and mapping_x.output_behavior == GamepadMapping.OUTPUT_BEHAVIOR.AXIS:
		return MODE.BUTTON
	if mapping_y and mapping_y.output_behavior == GamepadMapping.OUTPUT_BEHAVIOR.AXIS:
		return MODE.BUTTON
	
	if mapping_x and mapping_y and mapping_x.output_events.size() == 1 and mapping_y.output_events.size() == 1:
		if mapping_x.output_events[0].matches(mapping_y.output_events[0]):
			return MODE.JOYSTICK

	return MODE.AXIS


func set_mappings_from(profile: GamepadProfile) -> void:
	axes_mapping = profile.get_axes_mapping_for(pairs[0], pairs[1])
	if not axes_mapping.x:
		axes_mapping.x = GamepadMapping.new()
	if not axes_mapping.y:
		axes_mapping.y = GamepadMapping.new()


func set_as_trigger() -> void:
	dropdown.set_option_disabled(0, true)
	dropdown.set_option_disabled(2, true)


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
	
	if pairs.size() != 2:
		return
	_clear_buttons()
	var button := button_scene.instantiate() as CardMappingButton
	button.text = "-"
	button.set_mapping.call_deferred(pairs)

	axes_mapping.x.source_event = pairs[0]
	axes_mapping.x.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.SEQUENCE
	axes_mapping.y.source_event = pairs[1]
	axes_mapping.y.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.SEQUENCE

	button.set_meta("mappings", [axes_mapping.x, axes_mapping.y] as Array[GamepadMapping])
	button.button_up.connect(_on_button_pressed.bind(button))
	button.set_axis_type.call_deferred(button.AXIS_TYPE.NONE)
	add_child(button)

	buttons[pairs[0].get_signature()] = [button] as Array[CardMappingButton]


func _on_axis_mode_selected() -> void:
	
	if pairs.size() != 2:
		return
	_clear_buttons()
	var pair_type: int = get_meta("pair_type")
	var left_button := button_scene.instantiate() as CardMappingButton
	left_button.text = "-"
	left_button.set_mapping.call_deferred([pairs[0]] as Array[MappableEvent])

	axes_mapping.x.source_event = pairs[0]
	axes_mapping.x.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.SEQUENCE
	left_button.set_meta("mappings", [axes_mapping.x] as Array[GamepadMapping])
	left_button.button_up.connect(_on_button_pressed.bind(left_button))
	if pair_type == 2: #AxisPair.TYPE.TRIGGER
		left_button.set_axis_type.call_deferred(left_button.AXIS_TYPE.NONE)
	else:
		left_button.set_axis_type.call_deferred(left_button.AXIS_TYPE.X_FULL)
	add_child(left_button)
	buttons[pairs[0].get_signature()] = [left_button] as Array[CardMappingButton]

	var right_button := button_scene.instantiate() as CardMappingButton
	right_button.text = "-"
	right_button.set_mapping.call_deferred([pairs[1]] as Array[MappableEvent])

	axes_mapping.y.source_event = pairs[1]
	axes_mapping.y.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.SEQUENCE
	right_button.set_meta("mappings", [axes_mapping.y] as Array[GamepadMapping])
	right_button.button_up.connect(_on_button_pressed.bind(right_button))
	if pair_type == 2: #AxisPair.TYPE.TRIGGER
		right_button.set_axis_type.call_deferred(right_button.AXIS_TYPE.NONE)
	else:
		right_button.set_axis_type.call_deferred(right_button.AXIS_TYPE.Y_FULL)
	add_child(right_button)
	buttons[pairs[1].get_signature()] = [right_button] as Array[CardMappingButton]


func _on_button_mode_selected() -> void:
	
	if pairs.size() != 2:
		return
	_clear_buttons()
	axes_mapping.x.source_event = pairs[0]
	axes_mapping.x.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.AXIS
	axes_mapping.y.source_event = pairs[1]
	axes_mapping.y.output_behavior = GamepadMapping.OUTPUT_BEHAVIOR.AXIS

	for i in range(4):
		var button := button_scene.instantiate() as CardMappingButton
		button.text = "-"
		if i == 0:
			button.set_mapping.call_deferred([pairs[0]] as Array[MappableEvent])
			button.set_meta("output_index", 0)
			button.set_meta("mappings", [axes_mapping.x] as Array[GamepadMapping])
			button.set_axis_type.call_deferred(button.AXIS_TYPE.X_LEFT)
			buttons[pairs[0].get_signature()] = [button] as Array[CardMappingButton]
		if i == 1:
			button.set_mapping.call_deferred([pairs[0]] as Array[MappableEvent])
			button.set_meta("output_index", 1)
			button.set_meta("mappings", [axes_mapping.x] as Array[GamepadMapping])
			button.set_axis_type.call_deferred(button.AXIS_TYPE.X_RIGHT)
			buttons[pairs[0].get_signature()].append(button)
		if i == 2:
			button.set_mapping.call_deferred([pairs[1]] as Array[MappableEvent])
			button.set_meta("output_index", 0)
			button.set_meta("mappings", [axes_mapping.y] as Array[GamepadMapping])
			button.set_axis_type.call_deferred(button.AXIS_TYPE.Y_UP)
			buttons[pairs[1].get_signature()] = [button] as Array[CardMappingButton]
		if i == 3:
			button.set_mapping.call_deferred([pairs[1]] as Array[MappableEvent])
			button.set_meta("output_index", 1)
			button.set_meta("mappings", [axes_mapping.y] as Array[GamepadMapping])
			button.set_axis_type.call_deferred(button.AXIS_TYPE.Y_DOWN)
			buttons[pairs[1].get_signature()].append(button)
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

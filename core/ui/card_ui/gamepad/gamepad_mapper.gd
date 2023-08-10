extends Control
class_name GamepadMapper

const state_machine := preload(
	"res://assets/state/state_machines/gamepad_settings_state_machine.tres"
)
var change_input_state := load("res://assets/state/states/gamepad_change_input.tres") as State

signal mappings_selected(mappings: Array[GamepadMapping])

@export var keyboard: KeyboardInstance = load("res://core/global/keyboard_instance.tres")

var mappings: Array[GamepadMapping]
var output_index: int = 0
var keyboard_context := KeyboardContext.new(KeyboardContext.TYPE.INPUT_MAPPER)

@onready var input_texture_node := $%InputTexture as TextureRect
@onready var clear_button := $%ClearButton as CardButton
@onready var keyboard_button := $%KeyboardButton as CardButton
@onready var mouse_button := $%MouseButton as CardButton
@onready var mouse_container := $%MouseContainer as Control
@onready var mouse_left_button := $%LeftClickButton as CardButton
@onready var mouse_right_button := $%RightClickButton as CardButton
@onready var mouse_middle_button := $%MiddleClickButton as CardButton
@onready var mouse_motion_button := $%MouseMotionButton as CardButton
@onready var mouse_wheel_up_button := $%WheelUpButton as CardButton
@onready var mouse_wheel_down_button := $%WheelDownButton as CardButton
@onready var mouse_focus_group := $%MouseFocusGroup as FocusGroup


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_input_state.state_entered.connect(_on_state_entered)
	change_input_state.state_exited.connect(_on_state_exited)

	# Setup the clear button
	var on_clear_button := func():
		mappings_selected.emit(mappings)
		state_machine.pop_state()
	clear_button.button_up.connect(on_clear_button)

	# Setup the keyboard input select
	var on_keyboard_button := func():
		keyboard_context.mappings = mappings
		keyboard.open(keyboard_context)
	keyboard_button.button_up.connect(on_keyboard_button)

	# Setup the mouse input select
	var on_mouse_button := func():
		mouse_container.visible = true
		mouse_focus_group.grab_focus()
	mouse_button.button_up.connect(on_mouse_button)

	# Handle selecting a mouse input
	mouse_left_button.button_up.connect(_on_mouse_button.bind(MOUSE_BUTTON_LEFT))
	mouse_right_button.button_up.connect(_on_mouse_button.bind(MOUSE_BUTTON_RIGHT))
	mouse_middle_button.button_up.connect(_on_mouse_button.bind(MOUSE_BUTTON_MIDDLE))
	mouse_wheel_up_button.button_up.connect(_on_mouse_button.bind(MOUSE_BUTTON_WHEEL_UP))
	mouse_wheel_down_button.button_up.connect(_on_mouse_button.bind(MOUSE_BUTTON_WHEEL_DOWN))
	mouse_motion_button.button_up.connect(_on_mouse_motion)

	# Handle selecting a key input 
	keyboard_context.keymap_input_selected.connect(_on_key_selected)


func _on_state_entered(_from: State) -> void:
	var texture := change_input_state.get_meta("texture") as Texture2D
	mappings = change_input_state.get_meta("mappings") as Array[GamepadMapping]
	output_index = change_input_state.get_meta("output_index") as int
	input_texture_node.texture = texture
	mouse_container.visible = false
	mouse_motion_button.disabled = false


func _on_state_exited(_to: State) -> void:
	pass


func _on_mouse_button(button: MouseButton) -> void:
	var input_event := InputEventMouseButton.new()
	input_event.button_index = button
	var mappable_event := NativeEvent.new()
	mappable_event.event = input_event
	for mapping in mappings:
		if mapping.output_events.size() - 1 < output_index:
			mapping.output_events.resize(output_index+1)
		mapping.output_events[output_index] = mappable_event
	mappings_selected.emit(mappings)
	state_machine.pop_state()


func _on_mouse_motion() -> void:
	var input_event := InputEventMouseMotion.new()
	var mappable_event := NativeEvent.new()
	mappable_event.event = input_event
	for mapping in mappings:
		if mapping.output_events.size() - 1 < output_index:
			mapping.output_events.resize(output_index+1)
		mapping.output_events[output_index] = mappable_event
	mappings_selected.emit(mappings)
	state_machine.pop_state()


func _on_key_selected(event: MappableEvent) -> void:
	for mapping in mappings:
		if mapping.output_events.size() - 1 < output_index:
			mapping.output_events.resize(output_index+1)
		mapping.output_events[output_index] = event
	mappings_selected.emit(mappings)
	state_machine.pop_state()

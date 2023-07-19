extends Control

const state_machine := preload(
	"res://assets/state/state_machines/gamepad_settings_state_machine.tres"
)
var change_input_state := preload("res://assets/state/states/gamepad_change_input.tres") as State

signal mapping_selected(mapping: GamepadMapping)

@export var focus_node: Control
@export var keyboard: KeyboardInstance = preload("res://core/global/keyboard_instance.tres")

var input_texture: Texture2D
var mapping: GamepadMapping
var keyboard_context := KeyboardContext.new(KeyboardContext.TYPE.INPUT_MAPPER)

@onready var input_texture_node := $%InputTexture
@onready var keyboard_button := $%KeyboardButton
@onready var mouse_button := $%MouseButton
@onready var mouse_container := $%MouseContainer
@onready var mouse_left_button := $%LeftButton
@onready var mouse_right_button := $%RightButton
@onready var mouse_middle_button := $%MiddleButton
@onready var mouse_motion_button := $%MotionButton
@onready var mouse_wheel_up_button := $%WheelUpButton
@onready var mouse_wheel_down_button := $%WheelDownButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_input_state.state_entered.connect(_on_state_entered)
	change_input_state.state_exited.connect(_on_state_exited)

	# Setup the keyboard input select
	var on_keyboard_button := func():
		keyboard_context.mapping = mapping
		keyboard.open(keyboard_context)
	keyboard_button.pressed.connect(on_keyboard_button)

	# Setup the mouse input select
	var on_mouse_button := func():
		mouse_container.visible = true
		mouse_left_button.grab_focus.call_deferred()
		var event_name := mapping.get_source_event_name()
		if not event_name.begins_with("ABS"):
			mouse_motion_button.disabled = true
	mouse_button.pressed.connect(on_mouse_button)

	# Handle selecting a mouse input
	mouse_left_button.pressed.connect(_on_mouse_button.bind(MOUSE_BUTTON_LEFT))
	mouse_right_button.pressed.connect(_on_mouse_button.bind(MOUSE_BUTTON_RIGHT))
	mouse_middle_button.pressed.connect(_on_mouse_button.bind(MOUSE_BUTTON_MIDDLE))
	mouse_wheel_up_button.pressed.connect(_on_mouse_button.bind(MOUSE_BUTTON_WHEEL_UP))
	mouse_wheel_down_button.pressed.connect(_on_mouse_button.bind(MOUSE_BUTTON_WHEEL_DOWN))
	mouse_motion_button.pressed.connect(_on_mouse_motion)

	# Handle selecting a key input 
	keyboard_context.exited.connect(_on_key_selected)


func _on_state_entered(_from: State) -> void:
	input_texture_node.texture = input_texture
	mouse_container.visible = false
	mouse_motion_button.disabled = false
	focus_node.grab_focus.call_deferred()


func _on_state_exited(_to: State) -> void:
	pass


func _on_mouse_button(button: MouseButton) -> void:
	var input_event := InputEventMouseButton.new()
	input_event.button_index = button
	mapping.target = input_event
	mapping_selected.emit(mapping)
	state_machine.pop_state()


func _on_mouse_motion() -> void:
	var input_event := InputEventMouseMotion.new()
	mapping.target = input_event
	mapping.axis = mapping.AXIS.BOTH
	mapping_selected.emit(mapping)
	state_machine.pop_state()


func _on_key_selected() -> void:
	mapping_selected.emit(mapping)
	state_machine.pop_state()

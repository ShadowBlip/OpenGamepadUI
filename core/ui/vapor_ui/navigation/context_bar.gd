extends Control

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var logger := Log.get_logger("ContextBar")

@onready var accept_icon := $%AcceptButtonIcon as ControllerTextureRect
@onready var back_icon := $%BackButtonIcon as ControllerTextureRect
@onready var quick_bar_mod_icon := $%QBModifierIcon as ControllerTextureRect
@onready var quick_bar_button_icon := $%QBButtonIcon as ControllerTextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	ControllerIcons.input_type_changed.connect(_on_input_type_changed)


func _process(delta: float) -> void:
	var stack = []
	for s in state_machine._state_stack:
		var state := s as State
		stack.push_back(state.name)
	var state_stack = "-> ".join(stack)
	$MarginContainer/HBoxContainer/DebugLabel.text = state_stack


func _on_state_changed(from: State, to: State):
	var stack = []
	for s in state_machine._state_stack:
		var state := s as State
		stack.push_back(state.name)
	var state_stack = "-> ".join(stack)
	logger.debug(state_stack)


# Update the icons in the context bar based on input type
func _on_input_type_changed(input_type: ControllerIcons.InputType) -> void:
	if input_type == ControllerIcons.InputType.CONTROLLER:
		accept_icon.path = "joypad/a"
		back_icon.path = "joypad/b"
		quick_bar_mod_icon.path = "joypad/home"
		quick_bar_button_icon.path = "joypad/a"
	else:
		accept_icon.path = "ui_accept"
		back_icon.path = "ogui_east"
		quick_bar_mod_icon.path = "key/ctrl"
		quick_bar_button_icon.path = "ogui_guide_action_quick_bar"

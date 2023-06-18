@tool
extends HBoxContainer
class_name ControllerShortcutIcon

@export_category("Keyboard")
@export var keyboard_modifier := "key/ctrl"
@export var keyboard_key := "key/f1"
@export_category("Gamepad")
@export var gamepad_modifier := "joypad/home"
@export var gamepad_button := "joypad/a"


@onready var modifier_icon := $%ModifierIcon as ControllerTextureRect
@onready var plus_label := $%PlusLabel as Label
@onready var button_icon := $%ButtonIcon as ControllerTextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_input_type_changed(ControllerIcons.InputType.KEYBOARD_MOUSE)
	ControllerIcons.input_type_changed.connect(_on_input_type_changed)


# Update the icons in the context bar based on input type
func _on_input_type_changed(input_type: ControllerIcons.InputType) -> void:
	if input_type == ControllerIcons.InputType.CONTROLLER:
		modifier_icon.visible = gamepad_modifier != ""
		plus_label.visible = gamepad_modifier != ""
		modifier_icon.path = gamepad_modifier
		button_icon.path = gamepad_button
		return

	# Keyboard/mouse input type
	modifier_icon.visible = keyboard_modifier != ""
	plus_label.visible = keyboard_modifier != ""
	modifier_icon.path = keyboard_modifier
	button_icon.path = keyboard_key

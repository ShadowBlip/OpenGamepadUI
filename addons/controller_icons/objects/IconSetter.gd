@icon("res://assets/ui/icons/gamepad-bold.svg")
extends Node
class_name  ControllerIconSetter


@export var path : String = "":
	set(_path):
		path = _path
		if not is_inside_tree():
			return
		if not parent:
			return
		var icon: Texture2D
		if force_type > 0:
			icon = ControllerIcons.parse_path(path, force_type - 1)
		else:
			icon = ControllerIcons.parse_path(path)
		
		if "icon" in parent:
			parent.icon = icon
		elif "texture" in parent:
			parent.texture = icon

@export_enum("Both", "Keyboard/Mouse", "Controller") var show_only : int = 0:
	set(_show_only):
		show_only = _show_only
		_on_input_type_changed(ControllerIcons._last_input_type)

@export_enum("None", "Keyboard/Mouse", "Controller") var force_type : int = 0:
	set(_force_type):
		force_type = _force_type
		_on_input_type_changed(ControllerIcons._last_input_type)

@onready var parent := get_parent()


func _ready():
	ControllerIcons.input_type_changed.connect(_on_input_type_changed)
	self.path = path


func _on_input_type_changed(input_type):
	if show_only == 0 or \
		(show_only == 1 and input_type == ControllerIcons.InputType.KEYBOARD_MOUSE) or \
		(show_only == 2 and input_type == ControllerIcons.InputType.CONTROLLER):
		self.path = path
	else:
		if "icon" in parent:
			parent.icon = null
		elif "texture" in parent:
			parent.texture = null

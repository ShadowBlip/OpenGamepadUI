extends Resource
class_name KeyboardContext

enum TYPE {
	GODOT,
	X11,
}

signal submitted
signal entered
signal exited

var type: TYPE
var target: Control
var close_on_submit: bool = true


func _init(t: TYPE = TYPE.GODOT, tgt: Control = null, close_after_submit: bool = true) -> void:
	type = t
	target = tgt
	close_on_submit = close_after_submit

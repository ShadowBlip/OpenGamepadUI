extends Object
class_name KeyboardContext

enum TYPE {
	GODOT,
	X11,
}

var target: Control
var submit: Callable
var type: TYPE

func _init(t: TYPE = TYPE.GODOT, tgt: Control = null, sbmt: Callable = null) -> void:
	target = tgt
	submit = sbmt
	type = t

extends Object
class_name KeyboardContext

enum TYPE {
	GODOT,
	X11,
}

var type: TYPE
var target: Control
var submit: Callable
var close_on_submit: bool = false

func _init(t: TYPE = TYPE.GODOT, tgt: Control = null, sbmt: Callable = _on_submit, close_after_submit: bool = true) -> void:
	type = t
	target = tgt
	submit = sbmt
	close_on_submit = close_after_submit


func _on_submit(_text: String):
	pass

@tool
@icon("res://assets/editor-icons/fluent--draw-text-24-filled.svg")
extends BehaviorNode
class_name TextSetter

## Set text on the target [Label] node in reaction to a parent signal
##
## This [BehaviorNode] can be added as a child to any node and configured to
## listen for a signal. When the parent signal fires, this behavior will set
## the text on the given target [Label].

## The target [Label] to update with the given text when a parent signal fires
@export var target: Label:
	set(v):
		target = v
		if Engine.is_editor_hint():
			update_configuration_warnings()
## The text to set on the target label
@export var text: String = ""


## Set the current tab on the target node
func _on_signal(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null, _arg4: Variant = null):
	if not target:
		return
	target.text = tr(text)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()
	if not target:
		warnings.append("No target label configured!")
	return warnings

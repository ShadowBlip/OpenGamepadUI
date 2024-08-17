@tool
extends BehaviorNode
class_name TabSetter

## Set the current tab on a [TabContainer] in reaction to a parent signal
##
## This [BehaviorNode] can be added as a child to any node and configured to
## listen for a signal. When the parent signal fires, this behavior will set
## the current tab on the given target [TabContainer].

## The target [TabContainer] to update the current tab in response to a signal
@export var target: TabContainer:
	set(v):
		target = v
		if Engine.is_editor_hint():
			update_configuration_warnings()
## The current tab number to switch to
@export var tab_number: int = 0


## Set the current tab on the target node
func _on_signal(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null, _arg4: Variant = null):
	if not target:
		return
	target.current_tab = tab_number


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()
	if not target:
		warnings.append("No target tab container configured!")
	return warnings

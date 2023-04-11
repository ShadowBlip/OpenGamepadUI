extends Resource
class_name FocusStack

## Manages the focus flow using a stack
##
## Keeps track of levels of focus through a stack

signal focus_group_changed(group: FocusGroup)

var stack: Array[FocusGroup] = []
var logger := Log.get_logger("FocusStack", Log.LEVEL.DEBUG)


## Returns the currently focused focus group
func current_focus() -> FocusGroup:
	if stack.size() == 0:
		return null
	return stack[-1]


## Returns whether or not the given focus group is currently focused
func is_focused(group: FocusGroup) -> bool:
	if not group:
		return false
	if group == current_focus():
		return true
	return false


## Current size of the focus stack
func size() -> int:
	return stack.size()


## Push the given focus group to the top of the focus stack and call its
## grab_focus method
func push(group: FocusGroup) -> void:
	stack.push_back(group)
	logger.debug("Pushed focus stack: " + str(stack))
	focus_group_changed.emit(group)


## Remove and return the focus group at the top of the focus stack and call
## the next focus group's grab_focus method.
func pop() -> FocusGroup:
	if stack.size() == 0:
		return null
	var last := stack.pop_back() as FocusGroup
	if stack.size() > 0:
		focus_group_changed.emit(stack[-1])
	logger.debug("Popped focus stack: " + str(stack))
	return last

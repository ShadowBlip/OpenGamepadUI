@icon("res://assets/editor-icons/focus-field.svg")
extends Node
class_name FocusGroup

## Automatically manage focus for Control nodes in a container
##
## FocusGroup connects the focus neighbors of all control nodes in the given
## parent container.


@export_category("Focus Control")
## The current focus of the focus group
@export var current_focus: Control
## Menus with multiple levels of focus groups can be part of a chain of focus
@export var focus_stack: FocusStack
## The InputEvent that will trigger focusing a parent focus group
@export var back_action := "ogui_east"

@export_category("Focus Group Neighbors")
@export var focus_neighbor_bottom: FocusGroup
@export var focus_neighbor_top: FocusGroup
@export var focus_neighbor_left: FocusGroup
@export var focus_neighbor_right: FocusGroup

var neighbor_control := Control.new()
var logger := Log.get_logger("FocusGroup", Log.LEVEL.INFO)

@onready var parent := get_parent() as Control


# Called when the node enters the scene tree for the first time.
func _ready():
	# Create a focus stack if none is defined
	if not focus_stack:
		focus_stack = FocusStack.new()
	
	# Create a Control node child that nodes can set their focus neighbors to.
	# This can allow focus groups to neighbor other focus groups.
	neighbor_control.name = "FocusGroupNeighbor"
	neighbor_control.focus_entered.connect(grab_focus)
	neighbor_control.focus_mode = Control.FOCUS_ALL
	add_child(neighbor_control)
	
	# Listen for events that require recalculating the focus neighbors
	parent.child_entered_tree.connect(_on_child_tree_changed)
	parent.child_exiting_tree.connect(_on_child_tree_changed)
	if parent.has_signal("sort_children"):
		parent.sort_children.connect(recalculate_focus)
	recalculate_focus()
	set_process_input(parent.is_visible_in_tree())
	parent.visibility_changed.connect(_on_visibility_changed)
	
	# Try to find a focus node if one was not specified
	if not current_focus:
		current_focus = _find_focusable(parent.get_children(), parent)


## Recalculate the focus neighbors of the container's children
func recalculate_focus() -> void:
	logger.debug("Rebuilding the focus tree")
	# Get existing children so we can manage focus
	if parent.get_child_count() == 0:
		logger.debug("No children to set focus to; nothing to do.")
		return
	
	# Only update focus if the node is inside the scene tree
	if not is_inside_tree():
		logger.debug("Not updating focus; not yet in the scene tree")
		return

	var control_children: Array[Control] = []
	for child in parent.get_children():
		if not child is Control:
			continue
		if not child.is_inside_tree():
			continue
		if child.focus_mode != Control.FOCUS_ALL:
			continue
		control_children.append(child)
		if not child.focus_entered.is_connected(_on_child_focused):
			child.focus_entered.connect(_on_child_focused.bind(child))

	if control_children.size() == 0:
		logger.debug("No control children. Nothing to do.")
		return

	if control_children.size() == 1:
		logger.debug("One control child. Setting all focus neighbors to itself.")
		# Block leaving the UI element unless B button is pressed.
		var child := control_children[0]
		_single_set_focus_tree(child)
		return

	if parent is HFlowContainer:
		_hflow_set_focus_tree(control_children)
		return

	if parent is HBoxContainer:
		_hbox_set_focus_tree(control_children)
		return

	if parent is VBoxContainer:
		_vbox_set_focus_tree(control_children)
		return
	
	# For all others, try to recursively search for focusable children and
	# treat it like a VBoxContainer
	var focusable := _get_focusable_children(parent)
	_vbox_set_focus_tree(focusable)


## Grab focus on the currently focused node in the group and push this group
## to the top of the focus stack
func grab_focus() -> void:
	if not is_focused():
		focus_stack.push(self)
	if not current_focus:
		current_focus = _find_focusable(parent.get_children(), parent)
		logger.debug("Found focus node: " + str(current_focus))
	if current_focus:
		logger.info(parent.name + " grabbing focus on node: " + current_focus.name)
		current_focus.grab_focus.call_deferred()
		return
	logger.warn("Unable to find a focusable Control node")


## Returns true if this focus group is the currently focus in the focus stack.
func is_focused() -> bool:
	return focus_stack and focus_stack.current_focus() == self


## Returns true if this focus group is anywhere in the focus stack.
func is_in_focus_stack() -> bool:
	if not focus_stack:
		return false
	return focus_stack.is_in_stack(self)


## Intercept and handle back input to refocus a parent focus group when back
## is pressed
func _input(event: InputEvent) -> void:
	# Only process input if our parent is visible
	if not parent or not parent.is_visible_in_tree():
		return

	# Only handle back button pressed and when the guide button is not held
	if not event.is_action_pressed(back_action) or Input.is_action_pressed("ogui_guide"):
		return

	# Only handle input if a focus stack is defined
	if not focus_stack:
		return

	# If we're not the current focus group in the stack, let someone else handle
	# this input.
	if not focus_stack.is_focused(self):
		return
	
	# If we are the last focus group in the stack, let someone else handle this
	# input
	if focus_stack.size() == 1:
		return

	# Remove ourselves from the focus stack and get the parent focus group
	focus_stack.pop()
	var current_group := focus_stack.current_focus()

	# Stop the event from propagating
	logger.info(parent.name + " intercepting back input to refocus")
	get_viewport().set_input_as_handled()

	# Grab focus on our parent focus group
	current_group.grab_focus()


## Update the currently focused node on focus change
func _on_child_focused(child: Control) -> void:
	# Set the current focus to the focused child
	current_focus = child


## Stop processing input when not visible
func _on_visibility_changed() -> void:
	if parent.is_visible_in_tree():
		set_process_input(true)
		return
	set_process_input(false)


# Recursively tries to find a FocusGroup in the given array of nodes. Returns
# null if none are found.
func _find_child_focus_group(nodes: Array[Node], root: Node = null) -> FocusGroup:
	if nodes.size() == 0:
		logger.debug("Node has no children to check.")
		return null

	for node in nodes:
		var focusable: Node
		logger.debug("Considering node: " + node.name)
		# Check if node is a child FocusGroup
		if node is FocusGroup and node.get_parent() != root:
			return node
		# If the node is not a Control, try to find a child control node
		if not node is Control:
			logger.debug("Node not control. Checking children.")
			focusable = _find_child_focus_group(node.get_children(), root)
			if focusable:
				return focusable
			logger.debug("Node: " + node.name + " has no more children to check.")
			continue
		# Skip if the node is not visible
		if not node.visible:
			logger.debug("Node: " + node.name + " not visible. Skipping.")
			continue
		# Otherwise try and recursively find a child that can be focused
		logger.debug("Node: " + node.name + " is not focusable. Checking its children.")
		focusable = _find_child_focus_group(node.get_children(), root)
		if focusable:
			return focusable
	logger.debug("Node has no focusable children.")
	return null


# Recursively searches the given node children for a focusable node.
func _find_focusable(nodes: Array[Node], root: Node = null) -> Node:
	if nodes.size() == 0:
		logger.debug("Node has no children to check.")
		return null

	for node in nodes:
		var focusable: Node
		logger.debug("Considering node: " + node.name)
		# If the node is not a Control, try to find a child control node
		if not node is Control:
			logger.debug("Node not control. Checking children.")
			focusable = _find_focusable(node.get_children(), root)
			if focusable:
				return focusable
			logger.debug("Node: " + node.name + " has no more children to check.")
			continue
		# Skip if the node is not visible
		if not node.visible:
			logger.debug("Node: " + node.name + " not visible. Skipping.")
			continue
		# Skip if the node is a FocusGroupNeighbor node
		if node.name == "FocusGroupNeighbor":
			continue
		# If the Control node has FOCUS_ALL set, return it
		if node.focus_mode == Control.FOCUS_ALL:
			logger.debug("Found good node: " + node.name)
			return node
		# Otherwise try and recursively find a child that can be focused
		logger.debug("Node: " + node.name + " is not focusable. Checking its children.")
		focusable = _find_focusable(node.get_children(), root)
		if focusable:
			return focusable
	logger.debug("Node has no focusable children.")
	return null


# Recursively searches the given node for focusable children.
func _get_focusable_children(node: Control) -> Array[Control]:
	var focusable: Array[Control] = []
	if node.get_child_count() == 0:
		logger.debug("Node has no children to check.")
		return focusable

	for child in node.get_children():
		if _is_focusable(child):
			focusable.append(child)
		focusable.append_array(_get_focusable_children(child))
	
	return focusable


# Returns true if the given node is focusable
func _is_focusable(node: Node) -> bool:
	if node is FocusGroup:
		return true
	if node.name == "FocusGroupNeighbor":
		return false
	if node.get("focus_mode") == null:
		return false
	if node.focus_mode != Control.FOCUS_ALL:
		return false
	if not node.is_visible_in_tree():
		return false
	return true


# Called when nodes are added or removed from the parent
func _on_child_tree_changed(_node) -> void:
	logger.debug("Child tree changed.")
	recalculate_focus()


# Update the focus neighbors when only one child exists
func _single_set_focus_tree(child: Control) -> void:
	child.focus_next = child.get_path()
	child.focus_neighbor_bottom = child.get_path()
	child.focus_previous = child.get_path()
	child.focus_neighbor_top = child.get_path()
	child.focus_neighbor_left = child.get_path()
	child.focus_neighbor_right = child.get_path()
	if focus_neighbor_top:
		child.focus_neighbor_top = focus_neighbor_top.neighbor_control.get_path()
	if focus_neighbor_bottom:
		child.focus_neighbor_bottom = focus_neighbor_bottom.neighbor_control.get_path()
	if focus_neighbor_left:
		child.focus_neighbor_left = focus_neighbor_left.neighbor_control.get_path()
	if focus_neighbor_right:
		child.focus_neighbor_right = focus_neighbor_right.neighbor_control.get_path()
	_on_child_focused(child)


func _hflow_set_focus_tree(control_children: Array[Control]) -> void:
	var hflow := parent as HFlowContainer
	var lines := hflow.get_line_count()
	
	# If no lines exist, the flow container hasn't sorted its children yet.
	if lines == 0:
		return
		
	# Calculate the number of children per line
	# TODO: Use 'item_rect_changed' and child positions to determine focus
	var children_per_row := ceilf(float(control_children.size()) / lines)
	
	# Build a 2d array of the children
	var grid: Array[Array] = [[]]
	var y := 0
	for child in control_children:
		var row := grid[y]
		if row.size() >= children_per_row:
			y += 1
			grid.append([])
			row = grid[y]
		row.append(child)
	
	_grid_set_focus_tree(grid)


func _grid_set_focus_tree(control_children: Array[Array]) -> void:
	for y in range(control_children.size()):
		for x in range(control_children[y].size()):
			var row := control_children[y]
			var child := control_children[y][x] as Control

			# LEFT
			child.focus_neighbor_left = row[x-1].get_path()

			# UP
			var row_above := control_children[y-1]
			var top := _nearest_neighbor(x, row.size(), row_above.size())
			child.focus_neighbor_top = row_above[top].get_path()

			# RIGHT
			var right := x+1
			if right >= control_children[y].size():
				right = 0
			child.focus_neighbor_right = row[right].get_path()

			# BOTTOM
			var bottom_y := y+1
			if bottom_y >= control_children.size():
				bottom_y = 0
			var row_below := control_children[bottom_y]
			var bottom := _nearest_neighbor(x, row.size(), row_below.size())
			child.focus_neighbor_bottom = row_below[bottom].get_path()

			child.focus_next = child.focus_neighbor_right
			child.focus_previous = child.focus_neighbor_left
			
			# Set the focus group neighbors if they are defined
			if focus_neighbor_top and y == 0:
				child.focus_neighbor_top = focus_neighbor_top.neighbor_control.get_path()
			if focus_neighbor_bottom and y == control_children.size() - 1:
				child.focus_neighbor_bottom = focus_neighbor_bottom.neighbor_control.get_path()
			if focus_neighbor_left and x == 0:
				child.focus_neighbor_left = focus_neighbor_left.neighbor_control.get_path()
			if focus_neighbor_right and x == control_children[y].size() - 1:
				child.focus_neighbor_right = focus_neighbor_right.neighbor_control.get_path()


func _hbox_set_focus_tree(control_children: Array[Control]) -> void:
	var i := 0
	for child in control_children:
		# Index +1
		if i < control_children.size() - 1:
			child.focus_next = control_children[i + 1].get_path()
			child.focus_neighbor_right = control_children[i + 1].get_path()
		else:
			child.focus_next = control_children[0].get_path()
			child.focus_neighbor_right = control_children[0].get_path()

		# Index -1
		child.focus_previous = control_children[i - 1].get_path()
		child.focus_neighbor_left = control_children[i - 1].get_path()

		# Block leaving the UI element unless B button is pressed.
		child.focus_neighbor_top = control_children[i].get_path()
		child.focus_neighbor_bottom = control_children[i].get_path()
		
		# Set the focus group neighbors if they are defined
		if focus_neighbor_top:
			child.focus_neighbor_top = focus_neighbor_top.neighbor_control.get_path()
		if focus_neighbor_bottom:
			child.focus_neighbor_bottom = focus_neighbor_bottom.neighbor_control.get_path()
		if focus_neighbor_left and i == 0:
			child.focus_neighbor_left = focus_neighbor_left.neighbor_control.get_path()
		if focus_neighbor_right and i == control_children.size() - 1:
			child.focus_neighbor_right = focus_neighbor_right.neighbor_control.get_path()
		
		i += 1


func _vbox_set_focus_tree(control_children: Array[Control]) -> void:
	var i := 0
	for child in control_children:
		# Index +1
		if i < control_children.size() - 1:
			child.focus_next = control_children[i + 1].get_path()
			child.focus_neighbor_bottom = control_children[i + 1].get_path()
		else:
			child.focus_next = control_children[0].get_path()
			child.focus_neighbor_bottom = control_children[0].get_path()

		# Index -1
		child.focus_previous = control_children[i - 1].get_path()
		child.focus_neighbor_top = control_children[i - 1].get_path()

		# Block leaving the UI element unless B button is pressed.
		child.focus_neighbor_left = control_children[i].get_path()
		child.focus_neighbor_right = control_children[i].get_path()
		
		# Set the focus group neighbors if they are defined
		if is_instance_valid(focus_neighbor_top) and i == 0:
			child.focus_neighbor_top = focus_neighbor_top.neighbor_control.get_path()
		if is_instance_valid(focus_neighbor_bottom) and i == control_children.size() - 1:
			child.focus_neighbor_bottom = focus_neighbor_bottom.neighbor_control.get_path()
		if is_instance_valid(focus_neighbor_left):
			child.focus_neighbor_left = focus_neighbor_left.neighbor_control.get_path()
		if is_instance_valid(focus_neighbor_right):
			child.focus_neighbor_right = focus_neighbor_right.neighbor_control.get_path()

		i += 1


# Returns the index that closest matches how far the given index is in an array 
# of the given size in comparision to the given 'to_size'. 
# E.g. 
#   var a := [1, 2, 3]
#   var b := [1, 2, 3, 4, 5, 6]
#   _nearest_neighbor(2, a.size(), b.size())
# Returns index in 'b' array: 4
func _nearest_neighbor(idx: int, from_size: int, to_size: int) -> int:
	var factor := float(to_size) / float(from_size)
	var closest := int(round(idx * factor))
	if closest >= to_size:
		return to_size - 1
	return closest

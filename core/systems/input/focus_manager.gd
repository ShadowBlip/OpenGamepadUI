extends Node
class_name FocusManager

@export_category("Focus Control")
@export var current_focus: Control
@export_category("Refocus on input")
## If enabled, will intercept input and refocus on the current focus node instead
@export var process_input := false
## The InputEvent that will trigger refocusing the current focus node
@export var refocus_on := "ogui_east"
## If true, only intercept input and refocus if a descendent node has focus
@export var intercept_children_only := false
@export_category("Focus Stack")
## Menus with multiple levels of focus can be part of a chain of focus
@export var focus_stack: FocusStack

var logger := Log.get_logger("FocusManager", Log.LEVEL.INFO)

@onready var parent := get_parent() as Control


# Called when the node enters the scene tree for the first time.
func _ready():
	parent.child_entered_tree.connect(_on_child_tree_changed)
	parent.child_exiting_tree.connect(_on_child_tree_changed)
	recalculate_focus()
	set_process_input(process_input)
	if process_input:
		parent.visibility_changed.connect(_on_visibility_changed)
	
	# Flow containers need to recalculate focus whenever the container 
	# tries to sort its children
	if parent is FlowContainer:
		parent.sort_children.connect(recalculate_focus)


## Recalculate the focus neighbors of the container's children
func recalculate_focus() -> void:
	_on_child_tree_changed(null)


func _on_child_tree_changed(_node) -> void:
	logger.debug("Child tree changed. Rebuilding focus tree.")
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
		child.focus_next = child.get_path()
		child.focus_neighbor_bottom = child.get_path()
		child.focus_previous = child.get_path()
		child.focus_neighbor_top = child.get_path()
		child.focus_neighbor_left = child.get_path()
		child.focus_neighbor_right = child.get_path()
		_on_child_focused(child)
		return

	if parent is HFlowContainer:
		_hflow_set_focus_tree(control_children)
		return

	if parent is HBoxContainer:
		_hbox_set_focus_tree(control_children)
		return

	_vbox_set_focus_tree(control_children)


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
		i += 1


func _on_child_focused(child: Control) -> void:
	current_focus = child


func _on_visibility_changed() -> void:
	if parent.is_visible_in_tree():
		set_process_input(true)
		return
	set_process_input(false)


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


func _input(event: InputEvent) -> void:
	# Only process input if our parent is visible
	if not parent or not parent.is_visible_in_tree():
		return

	# Only handle back button pressed and when the guide button is not held
	if not event.is_action_pressed(refocus_on) or Input.is_action_pressed("ogui_guide"):
		return

	# Can't process what we don't have
	if not current_focus:
		return

	# If our focus children already have focus, let someone else handle this
	# input.
	if current_focus.has_focus():
		return

	# If the active focus node is not a decendent, let someone else handle this
	# input
	# TODO: Refactor using a concept of a focus tree, separate from the scene tree
	if intercept_children_only:
		var active_focus := get_viewport().gui_get_focus_owner()
		if not parent.is_ancestor_of(active_focus):
			return

	# Stop the event from propagating
	logger.info(parent.name + " intercepting back input to refocus")
	get_viewport().set_input_as_handled()

	# Grab focus on the current child
	current_focus.grab_focus.call_deferred()

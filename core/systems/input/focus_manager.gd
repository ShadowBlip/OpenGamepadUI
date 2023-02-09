extends Node
class_name FocusManager

@export_category("Focus Control")
@export var current_focus: Control
@export_category("Refocus on input")
@export var process_input := false
@export var refocus_on := "ogui_east"

var logger := Log.get_logger("FocusManager", Log.LEVEL.INFO)

@onready var parent := get_parent() as Control


# Called when the node enters the scene tree for the first time.
func _ready():
	parent.child_entered_tree.connect(_on_child_tree_changed)
	parent.child_exiting_tree.connect(_on_child_tree_changed)
	_on_child_tree_changed(null)
	set_process_input(process_input)
	if process_input:
		parent.visibility_changed.connect(_on_visibility_changed)


func _on_child_tree_changed(_node) -> void:
	# Get existing children so we can manage focus
	if parent.get_child_count() == 0:
		return

	var control_children: Array[Control] = []
	for child in parent.get_children():
		if not child is Control:
			continue
		control_children.append(child)
		child.focus_entered.connect(_on_child_focused.bind(child))

	if control_children.size() == 0:
		return

	if control_children.size() == 1:
		# Block leaving the UI element unless B button is pressed.
		var child := control_children[0]
		child.focus_next = child.get_path()
		child.focus_neighbor_bottom = child.get_path()
		child.focus_previous = child.get_path()
		child.focus_neighbor_top = child.get_path()
		child.focus_neighbor_left = child.get_path()
		child.focus_neighbor_right = child.get_path()
		return

	if parent is HBoxContainer:
		_hbox_set_focus_tree(control_children)
		return

	_vbox_set_focus_tree(control_children)


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

	# Stop the event from propagating
	logger.debug("Processing back input!")
	get_viewport().set_input_as_handled()

	# Grab focus on the current child
	current_focus.grab_focus.call_deferred()

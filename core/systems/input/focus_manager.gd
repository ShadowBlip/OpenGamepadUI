extends Node

@onready var parent := get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	parent.child_entered_tree.connect(_on_child_tree_changed)
	parent.child_exiting_tree.connect(_on_child_tree_changed)
	_on_child_tree_changed(null)


#TODO: Don't assume vbox
func _on_child_tree_changed(_node) -> void:
	# Get existing children so we can manage focus
	if parent.get_child_count() == 0:
		return

	var control_children: Array[Control] = []
	for child in parent.get_children():
		if not child is Control:
			continue
		control_children.append(child)

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

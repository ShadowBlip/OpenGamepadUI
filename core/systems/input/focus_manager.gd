extends Node


@onready var parent = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	parent.child_entered_tree.connect(_on_child_tree_changed)
	parent.child_exiting_tree.connect(_on_child_tree_changed)
	_on_child_tree_changed(null)


#TODO: Don't assume vbox
func _on_child_tree_changed(_node) -> void:
	print("on_child_tree_changed for ", parent.name)
	# Get existing children so we can manage focus
	if parent.get_child_count() == 0:
		return
	
	var control_children : Array[Control] = []
	for child in parent.get_children():
		if not child is Control:
			continue
		control_children.append(child)

	if control_children.size() == 0:
		return

	if control_children.size() == 1:
		# Block leaving the UI element unless B button is pressed.
		control_children[0].focus_next = control_children[0].get_path()
		control_children[0].focus_neighbor_bottom = control_children[0].get_path()
		control_children[0].focus_previous = control_children[0].get_path()
		control_children[0].focus_neighbor_top = control_children[0].get_path()
		control_children[0].focus_neighbor_left = control_children[0].get_path()
		control_children[0].focus_neighbor_right = control_children[0].get_path()
		return
		
	if parent is HBoxContainer:
		_hbox_set_focus_tree(control_children)
		return
		
	_vbox_set_focus_tree(control_children)


func _hbox_set_focus_tree(control_children: Array[Control]) -> void:
	print(parent.name, " is an HBOX.")
	for i in range(0, control_children.size()-1):
		# Index +1
		if i < control_children.size() -1:
			print("Connecting next ", control_children[i].name, " to ", control_children[i+1].name)
			control_children[i].focus_next = control_children[i+1].get_path()
			control_children[i].focus_neighbor_right = control_children[i+1].get_path()
		else:
			print("Connecting next INDEX LIMIT ", control_children[i].name, " to ", control_children[0].name)
			control_children[i].focus_next = control_children[0].get_path()
			control_children[i].focus_neighbor_right = control_children[0].get_path()
			
		# Index -1
		print("Connecting previous ", control_children[i].name, " to ", control_children[i-1].name)
		control_children[i].focus_previous = control_children[i-1].get_path()
		control_children[i].focus_neighbor_left = control_children[i-1].get_path()
		
		# Block leaving the UI element unless B button is pressed.
		control_children[i].focus_neighbor_top = control_children[i].get_path()
		control_children[i].focus_neighbor_bottom = control_children[i].get_path()


func _vbox_set_focus_tree(control_children: Array[Control]) -> void:
	print(parent.name, " is not an HBOX.")
	for i in range(0, control_children.size()-1):
		# Index +1
		if i < control_children.size() -1:
			print("Connecting next ", control_children[i].name, " to ", control_children[i+1].name)
			control_children[i].focus_next = control_children[i+1].get_path()
			control_children[i].focus_neighbor_bottom = control_children[i+1].get_path()
		else:
			print("Connecting next INDEX LIMIT ", control_children[i].name, " to ", control_children[0].name)
			control_children[i].focus_next = control_children[0].get_path()
			control_children[i].focus_neighbor_bottom = control_children[0].get_path()
			
		# Index -1
		print("Connecting previous ", control_children[i].name, " to ", control_children[i-1].name)
		control_children[i].focus_previous = control_children[i-1].get_path()
		control_children[i].focus_neighbor_top = control_children[i-1].get_path()
		
		# Block leaving the UI element unless B button is pressed.
		control_children[i].focus_neighbor_left = control_children[i].get_path()
		control_children[i].focus_neighbor_right = control_children[i].get_path()

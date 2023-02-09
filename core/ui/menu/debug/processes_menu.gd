extends Control

signal displays_updated

var selected_pid := -1

@onready var displays := Gamescope.discover_gamescope_displays()
@onready var refresh_timer := $RefreshTimer
@onready var pid_inspector := $%PIDInspector as Tree
@onready var kill_button := $%KillButton as Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Pause refresh when the inspector is not visible
	var on_visible_changed := func():
		if visible:
			refresh_timer.start()
			return
		refresh_timer.stop()
	visibility_changed.connect(on_visible_changed)
	refresh_timer.timeout.connect(_update_displays)
	refresh_timer.timeout.connect(_update_pid_tree)
	
	# Configure the PID inspector
	pid_inspector.set_column_title(0, "PID")
	pid_inspector.create_item()
	pid_inspector.item_selected.connect(_on_pid_selected)
	
	# Configure the kill Button
	kill_button.button_up.connect(_on_kill_pressed)

	if visible:
		refresh_timer.start()


# Triggers when a user selects an item in the PID inspector
func _on_pid_selected() -> void:
	var selected := pid_inspector.get_selected()
	var metadata = selected.get_metadata(0)
	if not metadata:
		selected_pid = -1
		kill_button.disabled = true
		return
	var pid := metadata as int
	selected_pid = pid
	kill_button.disabled = false


# Triggers when the kill button is pressed
func _on_kill_pressed() -> void:
	if selected_pid < 1:
		return
	Reaper.reap(selected_pid)
	OS.kill(selected_pid)
	kill_button.disabled = true


# Looks for gamescope displays at refresh interval
func _update_displays() -> void:
	if len(displays) != 0:
		return
	displays = Gamescope.discover_gamescope_displays()
	displays_updated.emit()


# Update the PID tree component
func _update_pid_tree() -> void:
	if len(displays) == 0:
		return
	
	# Get the PID tree component and get the root element
	var tree := pid_inspector
	var root := tree.get_root()

	# Loop through all displays and find any processes with windows
	for display in displays:
		
		# Create a display root element if it does not exist
		var display_str := "Display %s" % display
		var display_root: TreeItem
		for child in root.get_children():
			var text := child.get_text(0)
			if text == display_str:
				display_root = child
		if not display_root:
			display_root = tree.create_item(root)
			display_root.set_text(0, display_str)
		
		# Update the tree for the given display
		_update_tree_for_display(display, tree, display_root)


# Updates the given tree for the given display
func _update_tree_for_display(display: String, tree: Tree, root: TreeItem) -> void:

	# Get all windows for the given Gamescope display
	var windows_root := Gamescope.get_root_window_id(display)
	var windows_all := Gamescope.get_all_windows(display, windows_root)
	var pids := {}
	for window in windows_all:
		var pid := Gamescope.get_window_pid(display, window)
		if not pid in pids:
			pids[pid] = []
		pids[pid].append(window)
	
	# Create a list of tree nodes to add or remove
	var needs_creation := []
	var needs_removal := []

	# Get a list of all the current children in the tree so we can reconcile
	# it with what processes are currently running
	var tree_pids := []
	for child in root.get_children():
		var pid := child.get_metadata(0) as int
		if not pid in pids.keys():
			needs_removal.append(child)
		tree_pids.append(pid)

	# Find any tree nodes we need to create that don't have a tree node
	for pid in pids.keys():
		if not pid in tree_pids:
			needs_creation.append(pid)
	
	# Remove any children that need removal 
	for item in needs_removal:
		root.remove_child(item)

	# Add any new tree nodes 
	for pid in needs_creation:
		var pid_info := Reaper.get_pid_status(pid)
		var pid_child := tree.create_item(root)
		var pid_name := ""
		if "Name" in pid_info:
			pid_name = pid_info["Name"]
		pid_child.set_text(0, "{0} ({1})".format([pid, pid_name]))
		pid_child.set_metadata(0, pid)
		
		# Create a tree node for each window associated with the PID
		for window in pids[pid]:
			var window_child := tree.create_item(pid_child)
			var window_name := Gamescope.get_window_name(display, window)
			window_child.set_text(0, "Window {0} ({1})".format([window, window_name]))
			window_child.set_metadata(0, pid)


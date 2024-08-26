extends Control

var gamescope := load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance

## Currently selected PID
var _selected_pid := -1
## Map of gamescope displays to XWayland instance
## E.g. {":0": <XWayland>, ":1": <XWayland>}
var _xwaylands := {}

@onready var refresh_timer := $RefreshTimer as Timer
@onready var pid_inspector := $%PIDInspector as Tree
@onready var kill_button := $%KillButton as Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Discover Gamescope displays
	var xwaylands := gamescope.get_xwaylands()
	for xwayland in xwaylands:
		var xwayland_name := xwayland.name
		_xwaylands[xwayland_name] = xwayland
	
	# Pause refresh when the inspector is not visible
	var on_visible_changed := func():
		if visible:
			refresh_timer.start()
			return
		refresh_timer.stop()
	visibility_changed.connect(on_visible_changed)
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
		_selected_pid = -1
		kill_button.disabled = true
		return
	var pid := metadata as int
	_selected_pid = pid
	kill_button.disabled = false


# Triggers when the kill button is pressed
func _on_kill_pressed() -> void:
	if _selected_pid < 1:
		return
	Reaper.reap(_selected_pid)
	OS.kill(_selected_pid)
	kill_button.disabled = true


# Update the PID tree component
func _update_pid_tree() -> void:
	if _xwaylands.size() == 0:
		return
	
	# Get the PID tree component and get the root element
	var tree := pid_inspector
	var root := tree.get_root()

	# Loop through all displays and find any processes with windows
	for xwayland_name: String in _xwaylands.keys():
		# Create a display root element if it does not exist
		var display_str := "Display %s" % xwayland_name
		var display_root: TreeItem
		for child in root.get_children():
			var text := child.get_text(0)
			if text == display_str:
				display_root = child
		if not display_root:
			display_root = tree.create_item(root)
			display_root.set_text(0, display_str)
		
		# Update the tree for the given display
		_update_tree_for_display(xwayland_name, tree, display_root)


# Updates the given tree for the given display
func _update_tree_for_display(display_name: String, tree: Tree, root: TreeItem) -> void:
	if not display_name in _xwaylands:
		return
	var xwayland := _xwaylands[display_name] as GamescopeXWayland

	# Get all windows for the given Gamescope display
	var windows_root := xwayland.root_window_id
	var windows_all := xwayland.get_all_windows(windows_root)
	var pids := {}
	for window in windows_all:
		var window_pids := xwayland.get_windows_for_pid(window)
		for pid in window_pids:
			if not pid in pids:
				pids[pid] = []
			@warning_ignore("unsafe_method_access")
			pids[pid].append(window)
	
	# Create a list of tree nodes to add or remove
	var needs_creation: Array[int] = []
	var needs_removal: Array[TreeItem] = []

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
		for window: int in pids[pid]:
			var window_child := tree.create_item(pid_child)
			var window_name := xwayland.get_window_name(window)
			window_child.set_text(0, "Window {0} ({1})".format([window, window_name]))
			window_child.set_metadata(0, pid)

extends Control

const Gamescope := preload("res://core/global/gamescope.tres")

signal displays_updated

var trees: Array[Tree] = []
var focused_window := -1
var logger := Log.get_logger("GamescopeInspector")

@onready var displays := Gamescope.discover_gamescope_displays()
@onready var refresh_timer := $RefreshTimer
@onready var tree_container := $%TreeContainer
@onready var gamescope_props := $%GamescopeProperties as Tree
@onready var window_inspector := $%WindowInspector as Tree

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	logger.info("Found gamescope displays: " + " ".join(displays))
	displays_updated.connect(_build_menus)
	displays_updated.emit()
	refresh_timer.timeout.connect(_update_gamescope_properties)
	refresh_timer.timeout.connect(_update_displays)
	refresh_timer.timeout.connect(_update_window_trees)
	
	# Pause refresh when the inspector is not visible
	var on_visible_changed := func():
		if visible:
			refresh_timer.start()
			return
		refresh_timer.stop()
	visibility_changed.connect(on_visible_changed)
	
	# Configure the window inspector
	window_inspector.set_column_title(0, "Property")
	window_inspector.set_column_title(1, "Value")
	window_inspector.create_item()
	
	# Configure the columns of our gamescope properties
	var update_properties := {
		"GAMESCOPE_FOCUSED_WINDOW": func(display_name: String) -> String:
			var display := Gamescope.get_display_type(display_name)
			focused_window = Gamescope.get_focused_window(display)
			#var window_name := Gamescope.get_window_name(display, focused_window)
			return "{0}".format([focused_window]),
		"GAMESCOPE_FOCUSABLE_APPS": func(display_name: String) -> String:
			var display := Gamescope.get_display_type(display_name)
			var apps := Array(Gamescope.get_focusable_apps(display))
			return ", ".join(apps),
		"GAMESCOPE_FOCUSABLE_WINDOWS": func(display_name: String) -> String:
			var display := Gamescope.get_display_type(display_name)
			var apps := Array(Gamescope.get_focusable_windows(display))
			return ", ".join(apps),
		#"GAMESCOPE_FPS_LIMIT": func(display: String) -> String:
		#	return "{0}".format([Gamescope.get_fps_limit(display)])
	}
	gamescope_props.set_column_title(0, "Property")
	gamescope_props.set_column_title(1, "Value")
	var props_root := gamescope_props.create_item()
	for key in update_properties.keys():
		var prop := gamescope_props.create_item(props_root)
		prop.set_text(0, key)
		prop.set_text(1, "")
		prop.set_metadata(0, update_properties[key])

	if visible:
		refresh_timer.start()


func _update_displays() -> void:
	if len(displays) != 0:
		return
	displays = Gamescope.discover_gamescope_displays()
	displays_updated.emit()


func _update_gamescope_properties() -> void:
	if len(displays) == 0:
		return
	var gamescope_display := displays[0]
	var root := gamescope_props.get_root()
	for prop in root.get_children():
		var get_prop := prop.get_metadata(0) as Callable
		var value = get_prop.call(gamescope_display)
		if not value is String:
			continue
		prop.set_text(1, value)


func _build_menus() -> void:
	if len(displays) == 0:
		return
	for child in tree_container.get_children():
		child.queue_free()
	trees = []
	for display in displays:
		var container := VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var label := Label.new()
		label.text = "Display " + display
		container.add_child(label)
		
		var tree := Tree.new()
		tree.item_selected.connect(_on_tree_item_selected.bind(tree, display))
		tree.select_mode = Tree.SELECT_ROW
		tree.set("theme_override_font_sizes/font_size", 10)
		tree.columns = 3
		tree.column_titles_visible = true
		tree.set_column_title(0, "Window ID")
		tree.set_column_title(1, "Name")
		tree.set_column_title(2, "Focused")
		tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tree.hide_root = false
		tree.create_item()
		trees.append(tree)
		container.add_child(tree)
		tree_container.add_child(container)
	_update_window_trees()


func _on_tree_item_selected(tree: Tree, display_name: String):
	var display := Gamescope.get_display_type(display_name)
	var selected := tree.get_selected()
	var window_id := selected.get_metadata(0) as int
	var properties := Gamescope.list_xprops(window_id, display)
	
	var root := window_inspector.get_root()
	for child in root.get_children():
		root.remove_child(child)
		child.free()
	
	var xwayland := Gamescope.get_xwayland(display)
	for prop_name in properties:
		var prop := window_inspector.create_item(root)
		prop.set_text(0, prop_name)
		var val := Array(Gamescope._get_xprop_array(xwayland, window_id, prop_name))
		if val.size() == 0:
			continue
		prop.set_text(1, ", ".join(val))


func _update_window_trees() -> void:
	var i := 0
	for tree in trees:
		var display := displays[i]
		_update_tree(tree, display)
		i += 1


func _update_tree(tree: Tree, display_name: String) -> void:
	var display := Gamescope.get_display_type(display_name)
	var root := tree.get_root()
	var root_id := Gamescope.get_root_window_id(display)
	root.set_text(0, "({0})".format([root_id]))
	root.set_text(1, "Root")
	root.set_metadata(0, root_id)
	_update_leaves(tree, root, display_name)


func _update_leaves(tree: Tree, tree_parent: TreeItem, display_name: String):
	var display := Gamescope.get_display_type(display_name)
	var window_id: int = tree_parent.get_metadata(0)
	var window_children := Gamescope.get_window_children(window_id, display)
	
	# Get the window ids of the children
	var tree_children_windows := []
	for i in tree_parent.get_children():
		tree_children_windows.push_back(i.get_metadata(0))
	
	# Create a tree item for any missing windows
	for child in window_children:
		if child in tree_children_windows:
			continue
		var tree_child := tree.create_item(tree_parent)
		tree_child.set_metadata(0, child)
	
	# Remove any tree items that don't have a window
	for tree_child in tree_parent.get_children():
		if tree_child.get_metadata(0) in window_children:
			continue
		tree_parent.remove_child(tree_child)
		tree_child.free()
	
	# Break case for recursion
	if window_children.size() == 0:
		return
	
	# Recursively update children
	for tree_child in tree_parent.get_children():
		var child_window_id := tree_child.get_metadata(0) as int
		var window_name := Gamescope.get_window_name(child_window_id, display)
		tree_child.set_text(0, "({0})".format([child_window_id]))
		tree_child.set_text(1, window_name)
		if child_window_id == focused_window:
			tree_child.set_text(2, "focused")
		else:
			tree_child.set_text(2, "")
		_update_leaves(tree, tree_child, display_name)

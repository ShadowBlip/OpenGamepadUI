@tool
extends EditorPlugin

## Dock instance
var dock: Control


func _enter_tree() -> void:
	var version := _get_version()
	print("Loading OpenGamepadUI Plugin SDK ", version)
	# Initialization of the plugin goes here.
	# Load the dock scene and instantiate it.
	dock = preload("res://addons/plugin-sdk/core/ui/plugin_dock.tscn").instantiate()

	# Add the loaded scene to the docks.
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_control_from_docks(dock)
	# Erase the control from the memory.
	dock.free()


## Return the OGUI SDK version
func _get_version() -> String:
	var file := FileAccess.open("res://addons/plugin-sdk/plugin.cfg", FileAccess.READ)
	var text := file.get_as_text()
	for line in text.split("\n"):
		if not line.begins_with("version="):
			continue
		var parts := line.split('"')
		if parts.size() < 2:
			continue
		return "v" + parts[1]
	
	return "v0.0"

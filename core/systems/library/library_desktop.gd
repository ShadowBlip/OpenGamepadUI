extends Library

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var home := OS.get_environment("HOME")
var desktop_folders := settings_manager.get_value(
			"library.desktop",
			"folders",
			["/".join([home, ".local/share/applications"]), "/usr/share/applications"]
		) as Array


func _ready() -> void:
	get_library_launch_items()


func get_library_launch_items() -> Array:
	var launch_items := []
	for folder in desktop_folders:
		logger.debug("Searching for .desktop files in: " + folder)
		if not DirAccess.dir_exists_absolute(folder):
			logger.warn("Folder does not exist: " + folder)
			continue
		var files := DirAccess.get_files_at(folder)
		for file in files:
			var launch_item := _desktop_file_to_launch_item("/".join([folder, file]))
			if launch_item:
				launch_items.append(launch_item)
	return launch_items


func _desktop_file_to_launch_item(file: String) -> LibraryLaunchItem:
	var launch_item := LibraryLaunchItem.new()
	launch_item.provider_app_id = file
	launch_item.installed = true
	launch_item.categories = []

	var f := FileAccess.open(file, FileAccess.READ)
	var text := f.get_as_text()
	var lines := text.split("\n")
	for line in lines:
		if line.begins_with("Name="):
			launch_item.name = line.replace("Name=", "")
			continue
		if line.begins_with("Exec="):
			var cmdline := line.replace("Exec=", "").split(" ") as Array
			launch_item.command = cmdline.pop_front()
			launch_item.args = cmdline
			continue
		if line.begins_with("Categories="):
			launch_item.categories = line.replace("Categories=", "").split(";", false)
			continue
		if line.begins_with("Keywords="):
			launch_item.tags = line.replace("Keywords=", "").split(";", false)
			continue

	if launch_item.name == "" or launch_item.command == "":
		return null

	# Only return items that are in the 'Game' category for now
	# TODO: Return all launch items but default to hidden and give users a
	# way to unhide them so they show up in their library.
	if not "Game" in launch_item.categories:
		return null

	# Apply any launch quirks if applicable
	_apply_quirks(launch_item)

	return launch_item


func _apply_quirks(launch_item: LibraryLaunchItem) -> void:
	if launch_item.command != "steam":
		return
	if launch_item.args.size() == 0:
		return
	if "-silent" in launch_item.args:
		return
	if not _contains_string(launch_item.args, "steam://rungameid"):
		return
		
	# If the desktop shortcut is for Steam, add the '-silent' argument so it
	# doesn't launch into the Steam interface
	#var args := PackedStringArray(["-gamepadui", "-steamos3", "-steampal", "-steamdeck", "-silent"])
	var args := PackedStringArray(["-silent"])
	args.append_array(launch_item.args)
	launch_item.args = args


func _contains_string(arr: PackedStringArray, string: String) -> bool:
	for item in arr:
		if string in item:
			return true
	return false

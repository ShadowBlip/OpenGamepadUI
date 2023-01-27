extends Library

var home := OS.get_environment("HOME")
var desktop_folders := SettingsManager.get_value(
	"library.desktop", 
	"folders", 
	["/".join([home, ".local/share/applications"])]
)

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
	
	if launch_item.name == "" or launch_item.command == "":
		return null
	
	return launch_item

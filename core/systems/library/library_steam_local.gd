extends Library

var home := OS.get_environment("HOME")
var steam_path := "/".join([home, ".steam", "steam"])
var steam_config_path := "/".join([steam_path, "config"])
var library_file_path := "/".join([steam_config_path, "libraryfolders.vdf"])
var steam_api_client := SteamAPIClient.new()


func _ready() -> void:
	add_child(steam_api_client)


func get_library_launch_items() -> Array:
	var launch_items := []
	if not DirAccess.dir_exists_absolute(steam_config_path):
		logger.debug("No Steam installation directory was found at: " + steam_path)
		return launch_items
	
	# Discover the app ids of installed apps
	var app_ids := get_installed_app_ids()

	# Get the app details for each app.
	for app_id in app_ids:
		logger.debug("Fetching app info for app_id: " + app_id)
		var info = await steam_api_client.get_app_details(app_id)
		if info == null:
			logger.debug("Unable to fetch app info for app id: " + app_id)
			continue
		var launch_item := _app_info_to_launch_item(info)
		if not launch_item:
			continue
		launch_items.append(launch_item)

	return launch_items


## Return a list of Steam app IDs that are locally installed
func get_installed_app_ids() -> PackedStringArray:
	var app_ids := PackedStringArray()
	if not FileAccess.file_exists(library_file_path):
		logger.warn("libraryfolders.vdf does not exist")
		return app_ids

	# Open the library folders
	var library_data := FileAccess.get_file_as_string(library_file_path)
	
	# Try to parse the library file
	var vdf := VDFParser.new()
	if vdf.parse(library_data) != OK:
		var err := vdf.get_error_message()
		var line_no := vdf.get_error_line()
		logger.warn("Unable to parse library data on line {0}: {1}".format([line_no, err]))
		return app_ids
	var library_dict := vdf.get_data()

	# Get the app ids from the parsed libraryfolders.vdf
	if not "libraryfolders" in library_dict:
		logger.warn("libraryfolders key not found in vdf")
		return app_ids
	if not library_dict is Dictionary:
		return app_ids
	var library_indexes := (library_dict["libraryfolders"] as Dictionary).keys()
	for idx in library_indexes:
		var libraryfolder := library_dict["libraryfolders"][idx] as Dictionary
		if not "apps" in libraryfolder:
			continue
		var apps := (libraryfolder["apps"] as Dictionary).keys()
		app_ids.append_array(apps)

	return app_ids


# Builds a library launch item from the given Steam app information.
func _app_info_to_launch_item(info: Dictionary) -> LibraryLaunchItem:
	if info.size() == 0:
		return null

	var app_id := info.keys()[0] as String
	var details := info[app_id] as Dictionary
	if not "data" in details:
		return null
	var data := details["data"] as Dictionary
	if not "type" in data:
		return null
	if not data["type"] == "game":
		return null
	var categories := PackedStringArray()
	if "categories" in data:
		for category in data["categories"]:
			categories.append(category["description"])
	var tags := PackedStringArray()
	if "genres" in data:
		for genre in data["genres"]:
			tags.append((genre["description"] as String).to_lower())

	var item := LibraryLaunchItem.new()
	item.provider_app_id = app_id
	item.name = data["name"]
	item.command = "steam"
	item.args = ["-gamepadui", "-steamos3", "-steampal", "-steamdeck", "-silent", "steam://rungameid/" + app_id]
	item.categories = categories
	item.tags = ["steam"]
	item.tags.append_array(tags)
	item.installed = true
		
	return item

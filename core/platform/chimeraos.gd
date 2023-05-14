extends PlatformProvider
class_name PlatformChimeraOS

var HOME := OS.get_environment("HOME")
var DESKTOP_PATH := "/".join([HOME, ".local", "share", "applications"])
var DESKTOP_FILENAME := "return-opengamepadui.desktop"
var DESKTOP_FILE_PATH := "/".join([DESKTOP_PATH, DESKTOP_FILENAME])
var ICON_PATH := "/".join([HOME, ".local", "share", "icons", "hicolor", "scalable", "apps"])
var ICON_FILENAME := "opengamepadui.svg"
var ICON_FILE_PATH := "/".join([ICON_PATH, ICON_FILENAME])
const DESKTOP_FILE := "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Name=Return to OpenGamepadUI
GenericName=Game launcher and overlay
Type=Application
Comment=Game launcher and overlay
Icon=opengamepadui
Exec=chimera-session opengamepadui
Terminal=false"


func _init() -> void:
	logger.set_name("PlatformChimeraOS")
	_ensure_desktop_icon()
	_ensure_desktop_file()


func ready(root: Window) -> void:
	if not _has_session_switcher():
		logger.info("No session switcher script detected")
		return
	_add_session_switcher(root)


## Add a button to the power menu to allow session switching
func _add_session_switcher(root: Window) -> void:
	# Get the power menu
	var power_menu := root.get_tree().get_first_node_in_group("power_menu")
	if not power_menu:
		logger.warn("No power menu was found. Unable to add session switcher.")
		return
	
	# Create a button that will perform the session switching
	var button_scene := load("res://core/ui/components/card_button.tscn") as PackedScene
	var switch_to_steam := button_scene.instantiate() as CardButton
	switch_to_steam.click_focuses = false
	switch_to_steam.text = "Switch to Steam"
	switch_to_steam.pressed.connect(_switch_session.bind("gamepadui"))
	
	var switch_to_steam_qam := button_scene.instantiate() as CardButton
	switch_to_steam_qam.click_focuses = false
	switch_to_steam_qam.text = "Switch to Steam with QAM"
	switch_to_steam_qam.pressed.connect(_switch_session.bind("gamepadui-with-qam"))
	
	var switch_to_desktop := button_scene.instantiate() as CardButton
	switch_to_desktop.click_focuses = false
	switch_to_desktop.text = "Switch to Desktop"
	switch_to_desktop.pressed.connect(_switch_session.bind("desktop"))
	
	# Add the buttons just above the exit button
	var exit_button := power_menu.exit_button as Control
	var container := exit_button.get_parent()
	container.add_child(switch_to_steam)
	container.move_child(switch_to_steam, exit_button.get_index())
	container.add_child(switch_to_steam_qam)
	container.move_child(switch_to_steam_qam, exit_button.get_index())
	container.add_child(switch_to_desktop)
	container.move_child(switch_to_desktop, exit_button.get_index())
	
	# Coerce the focus group to recalculate the focus neighbors
	var focus_group := power_menu.focus_group as FocusGroup
	focus_group.recalculate_focus()


## Returns true if we detect the session switching script
func _has_session_switcher() -> bool:
	return OS.execute("which", ["chimera-session"]) == 0


## Ensure there is a "Return to OpenGamepadUI" desktop shortcut
func _ensure_desktop_file() -> void:
	# Create the desktop entry
	if FileAccess.file_exists(DESKTOP_FILE_PATH):
		return
	if not DirAccess.dir_exists_absolute(DESKTOP_PATH):
		DirAccess.make_dir_recursive_absolute(DESKTOP_PATH)
	var desktop_file := FileAccess.open(DESKTOP_FILE_PATH, FileAccess.WRITE)
	desktop_file.store_string(DESKTOP_FILE)
	desktop_file.close()
	OS.execute("chmod", ["+x", DESKTOP_FILE_PATH])
	
	# Ensure that there's a dashboard entry
	var favorites := get_gnome_favorites()
	if DESKTOP_FILENAME in favorites:
		return
	favorites.append(DESKTOP_FILENAME)
	set_gnome_favorites(favorites)


## Ensure the OpenGamepadUI icon exists
func _ensure_desktop_icon() -> void:
	if FileAccess.file_exists(ICON_FILE_PATH):
		return
	if not DirAccess.dir_exists_absolute(ICON_PATH):
		DirAccess.make_dir_recursive_absolute(ICON_PATH)
	var bytes := FileAccess.get_file_as_bytes("res://icon.svg")
	var icon_file := FileAccess.open(ICON_FILE_PATH, FileAccess.WRITE)
	icon_file.store_buffer(bytes)
	icon_file.flush()


## Sets the gnome dashboard favorites to the given desktop items
func set_gnome_favorites(favorites: PackedStringArray) -> int:
	var apps_format := "[{0}]"
	var apps_arr: Array[String] = []
	for fav in favorites:
		apps_arr.append("'" + fav + "'")
	var apps := apps_format.format([", ".join(apps_arr)])
	
	var output := []
	var code := OS.execute("gsettings", ["set", "org.gnome.shell", "favorite-apps", apps], output)
	if code != OK:
		logger.error("Unable to pin OpenGamepadUI shortcut to dashboard: " + output[0])
	return code


## Return all the pinned dashboard items
## [gamer@chimeraos ~]$ gsettings get org.gnome.shell favorite-apps
## ['org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop']
func get_gnome_favorites() -> PackedStringArray:
	var output := []
	if OS.execute("gsettings", ["get", "org.gnome.shell", "favorite-apps"], output) != OK:
		return PackedStringArray()
	var stdout := output[0] as String
	stdout = stdout.replace("[", "")
	stdout = stdout.replace("]", "")
	stdout = stdout.replace("'", "")
	stdout = stdout.replace("\"", "")
	stdout = stdout.replace(" ", "")
	stdout = stdout.strip_edges()
	var favorites := stdout.split(",")
	
	return PackedStringArray(favorites)
	


## Switch to the given session
func _switch_session(name: String) -> void:
	var out: Array = []
	var code := OS.execute("chimera-session", [name], out)
	if code != OK:
		logger.error("Unable to switch sessions: " + out[0])

extends OSPlatform
class_name PlatformManjaro

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var default_theme := "res://assets/themes/card_ui-water-vapor.tres"


func _init() -> void:
	logger.set_name("PlatformManjaro")


func ready(root: Window) -> void:
	_set_default_theme(root)


## Sets the default theme.
func _set_default_theme(root: Window) -> void:
	# Set the default theme if there is no theme set
	var user_theme := settings_manager.get_value("general", "theme", "") as String
	if user_theme == "":
		logger.debug("No theme set. Using OS specific default theme: " + default_theme)
		settings_manager.set_value("general", "theme", default_theme)
	else :
		logger.debug("Found existing theme: " + user_theme)


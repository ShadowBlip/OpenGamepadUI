extends Resource
class_name SettingsManager

## Get and set user settings
##
## The SettingsManager is a simple class responsible for getting and setting 
## user-specific settings. These settings are stored in a single file at 
## user://settings.cfg.

signal setting_changed(section: String, key: String, value: Variant)

@export var settings_file := "user://settings.cfg"

var _config: ConfigFile = ConfigFile.new()
var logger := Log.get_logger("SettingsManager")


func _init() -> void:
	if not FileAccess.file_exists(settings_file):
		logger.info("No settings found. Creating settings file.")
		save()
		return
	logger.info("Loaded settings")
	reload()


func save() -> void:
	if _config.save(settings_file) != OK:
		logger.error("Unable to save settings!")


func reload() -> void:
	if _config.load(settings_file) != OK:
		logger.error("Unable to load settings!")


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	return _config.get_value(section, key, default)


func get_library_value(item: LibraryItem, key: String, default: Variant = null) -> Variant:
	var section := ".".join(["game", item.name.to_lower()])
	return get_value(section, key, default)


func set_value(section: String, key: String, value: Variant, persist: bool = true) -> void:
	_config.set_value(section, key, value)
	if persist:
		save()
	setting_changed.emit(section, key, value)


func set_library_value(item: LibraryItem, key: String, value: Variant, persist: bool = true) -> void:
	var section := ".".join(["game", item.name.to_lower()])
	set_value(section, key, value, persist)


func erase_section_key(section: String, key: String, persist: bool = true) -> void:
	_config.erase_section_key(section, key)
	if persist:
		save()
	setting_changed.emit(section, key, null)


func erase_library_key(item: LibraryItem, key: String, persist: bool = true) -> void:
	var section := ".".join(["game", item.name.to_lower()])
	erase_section_key(section, key, persist)

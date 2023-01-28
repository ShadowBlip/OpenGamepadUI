extends Node

signal setting_changed(section: String, key: String, value: Variant)

const settings_file := "user://settings.cfg"

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


func set_value(section: String, key: String, value: Variant, persist: bool = true) -> void:
	_config.set_value(section, key, value)
	if persist:
		save()
	setting_changed.emit(section, key, value)

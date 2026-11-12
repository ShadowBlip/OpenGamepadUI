@icon("res://assets/editor-icons/game-icons--power-generator.svg")
extends Node
class_name PowerStation

## Proxy interface to PowerStation over DBus
##
## Provides wrapper classes and methods for interacting with PowerStation over
## DBus to control CPU and GPU performance and fans.

@export var instance: PowerStationInstance = load("res://core/systems/performance/power_station.tres") as PowerStationInstance

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager

# Keep a reference to instances so they are not cleaned up automatically
var _cpu: Cpu
var _fan: Fan
var _gpu: Gpu
var logger := Log.get_logger("PowerStation")


func _ready() -> void:
	_cpu = instance.get_cpu()
	_fan = instance.get_fan()
	_gpu = instance.get_gpu()
	instance.started.connect(_load_fan_setting)
	settings_manager.setting_changed.connect(_on_setting_changed)


func _on_setting_changed(section: String, _key: String, _value: Variant) -> void:
	if section != "fan":
		return
	_load_fan_setting()


## Loads the fan profile chosen in the "fan" settings section. PowerStation
## does not save fan profiles, so this runs every time PowerStation starts.
func _load_fan_setting() -> void:
	if not _fan:
		return
	var profile := settings_manager.get_value("fan", "profile", "") as String
	if profile.is_empty():
		return

	var result: Error
	match profile:
		"automatic":
			result = _fan.load_profile_json(JSON.stringify({"name": "Automatic", "fans": []}))
		"manual":
			result = _load_manual_fan_profile()
		_:
			result = _fan.load_profile(profile)
	if result != OK:
		logger.warn("Failed to load fan profile '" + profile + "': " + error_string(result))


## Runs every fan at the percentage saved in the "fan" settings section
func _load_manual_fan_profile() -> Error:
	var percent := settings_manager.get_value("fan", "manual_percent", 50) as int
	var sensors := _fan.get_sensors()
	var fans: Array[Dictionary] = []
	for id: String in _fan.get_fan_ids():
		fans.append({"fan": id, "mode": "manual", "percent": percent, "sensors": sensors})
	return _fan.load_profile_json(JSON.stringify({"name": "Manual", "fans": fans}))


func _process(_delta: float) -> void:
	if not instance:
		return
	instance.process()

extends VBoxContainer

## Quick bar menu to choose a PowerStation fan profile
##
## Saves the choice in the "fan" settings section. [PowerStation] loads it.

var power_station := load("res://core/systems/performance/power_station.tres") as PowerStationInstance
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager

# Setting value for each dropdown item: "automatic", profile paths, then "manual"
var _profiles := PackedStringArray()

@onready var focus_group := $%FocusGroup as FocusGroup
@onready var profile_dropdown := $%ProfileDropdown as Dropdown
@onready var manual_slider := $%ManualSlider as ValueSlider
@onready var apply_timer := $%ApplyTimer as Timer


func _ready() -> void:
	manual_slider.value = settings_manager.get_value("fan", "manual_percent", 50) as int
	_update()
	power_station.started.connect(_update)
	power_station.stopped.connect(_update)
	profile_dropdown.item_selected.connect(_on_profile_selected)
	manual_slider.value_changed.connect(_on_manual_changed)
	apply_timer.timeout.connect(_on_apply_timer_timeout)


## Lists the fan profiles for this device. Hides the card if PowerStation
## cannot control any fans.
func _update() -> void:
	var fan := power_station.get_fan()
	var has_fans := fan != null and not fan.get_fan_ids().is_empty()
	var card := owner as Control
	if card:
		card.visible = has_fans
	if not has_fans:
		return

	_profiles = PackedStringArray(["automatic"])
	_profiles.append_array(fan.get_profiles())
	_profiles.append("manual")
	profile_dropdown.clear()
	for profile: String in _profiles:
		profile_dropdown.add_item(_get_label(profile))

	var current := settings_manager.get_value("fan", "profile", "automatic") as String
	profile_dropdown.select(maxi(_profiles.find(current), 0))
	manual_slider.visible = current == "manual"
	focus_group.recalculate_focus.call_deferred()


func _get_label(profile: String) -> String:
	if profile == "automatic":
		return "Automatic"
	if profile == "manual":
		return "Manual"
	return profile.get_file().get_basename().capitalize()


func _on_profile_selected(index: int) -> void:
	if index < 0 or index >= _profiles.size():
		return
	var profile := _profiles[index]
	manual_slider.visible = profile == "manual"
	settings_manager.set_value("fan", "profile", profile)


func _on_manual_changed(_value: float) -> void:
	apply_timer.start()


func _on_apply_timer_timeout() -> void:
	settings_manager.set_value("fan", "manual_percent", int(manual_slider.value))

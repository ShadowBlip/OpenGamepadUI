extends VBoxContainer

const SLIDER_SCENE := preload("res://core/ui/components/slider.tscn")

var power_station := load("res://core/systems/performance/power_station.tres") as PowerStationInstance
var fans: Array = []
var selected_fan
var curve_temperature_sliders: Array[ValueSlider] = []
var curve_percent_sliders: Array[ValueSlider] = []
var syncing := false
var compatible := false

@onready var focus_group := $%FocusGroup as FocusGroup
@onready var service_timer := $%ServiceTimer as Timer
@onready var apply_timer := $%ApplyTimer as Timer
@onready var fan_dropdown := $%FanDropdown as Dropdown
@onready var telemetry_label := $%TelemetryLabel as Label
@onready var backend_label := $%BackendLabel as Label
@onready var status_label := $%StatusLabel as Label
@onready var limits_label := $%LimitsLabel as Label
@onready var mode_dropdown := $%ModeDropdown as Dropdown
@onready var preset_dropdown := $%PresetDropdown as Dropdown
@onready var manual_slider := $%ManualSlider as ValueSlider
@onready var curve_section := $%CurveSection as Control
@onready var curve_points := $%CurvePoints as VBoxContainer


func _ready() -> void:
	mode_dropdown.clear()
	mode_dropdown.add_item("Automatic")
	mode_dropdown.add_item("Manual")
	mode_dropdown.add_item("Curve")
	fan_dropdown.item_selected.connect(_on_fan_selected)
	mode_dropdown.item_selected.connect(_on_mode_selected)
	preset_dropdown.item_selected.connect(_on_preset_selected)
	manual_slider.value_changed.connect(_on_manual_changed)
	service_timer.timeout.connect(_refresh_devices)
	apply_timer.timeout.connect(_apply_curve)
	if power_station:
		power_station.started.connect(_refresh_devices)
		power_station.stopped.connect(_on_service_stopped)
	_refresh_devices()


func _refresh_devices() -> void:
	var collection = power_station.get_fan() if power_station else null
	if collection:
		collection.refresh()
		fans = Array(collection.get_fans())
	else:
		fans = []
	_set_card_available(should_show_card(fans.size()))
	if fans.is_empty():
		_clear_selected_fan()
		return

	var selected_path := ""
	if selected_fan:
		selected_path = selected_fan.get_dbus_path()
	fan_dropdown.clear()
	var selected_index := 0
	for index in fans.size():
		var fan = fans[index]
		fan_dropdown.add_item(fan.get_name())
		if fan.get_dbus_path() == selected_path:
			selected_index = index
	fan_dropdown.visible = should_show_selector(fans.size())
	_select_fan(selected_index)


func _select_fan(index: int) -> void:
	if index < 0 or index >= fans.size():
		return
	var next_fan = fans[index]
	if selected_fan != next_fan:
		apply_timer.stop()
		if selected_fan and selected_fan.updated.is_connected(_sync_view):
			selected_fan.updated.disconnect(_sync_view)
		_clear_curve_controls()
	selected_fan = next_fan
	fan_dropdown.select(index)
	if not selected_fan.updated.is_connected(_sync_view):
		selected_fan.updated.connect(_sync_view)
	_sync_view()


func _sync_view() -> void:
	if not selected_fan:
		return
	syncing = true
	compatible = supports_api_version(selected_fan.get_api_version())
	var editing := not apply_timer.is_stopped()
	if not compatible:
		apply_timer.stop()
		editing = false
	var telemetry_valid: bool = selected_fan.get_telemetry_valid()
	if telemetry_valid:
		var effective: int = selected_fan.get_effective_percent()
		var duty_text: String = "firmware" if effective < 0 else "%d%%" % effective
		telemetry_label.text = "%.1f C  |  %d RPM  |  %s" % [
			selected_fan.get_temperature_c(), selected_fan.get_rpm(), duty_text]
	else:
		telemetry_label.text = "Telemetry unavailable"
	backend_label.text = "Backend: %s" % _display_backend(selected_fan.get_backend())
	limits_label.text = describe_limits(
		selected_fan.get_minimum_percent(),
		selected_fan.get_minimum_running_percent(),
		selected_fan.get_stop_temperature_c(),
		selected_fan.get_restart_temperature_c(),
		selected_fan.get_full_speed_temperature_c(),
		selected_fan.get_emergency_handoff_temperature_c())
	status_label.text = describe_state({
		"compatible": compatible,
		"fault": selected_fan.get_fault(),
		"automatic_verified": selected_fan.get_automatic_verified(),
		"suspended": selected_fan.get_suspended(),
		"mode": selected_fan.get_mode(),
	})

	if not editing:
		mode_dropdown.disabled = not compatible
		mode_dropdown.select(mode_to_index(selected_fan.get_mode()))
		manual_slider.min_value = selected_fan.get_minimum_percent()
		manual_slider.value = selected_fan.get_manual_percent()
		manual_slider.editable = compatible
		manual_slider.visible = selected_fan.get_mode() == "manual"
		_populate_presets()
		var curve_visible: bool = selected_fan.get_mode() in ["curve", "preset"]
		preset_dropdown.visible = curve_visible
		curve_section.visible = curve_visible
		if curve_visible:
			_rebuild_curve()
	syncing = false
	focus_group.recalculate_focus.call_deferred()


func _populate_presets() -> void:
	var presets: PackedStringArray = selected_fan.get_presets()
	var active: String = selected_fan.get_active_preset()
	preset_dropdown.clear()
	preset_dropdown.add_item("Custom")
	var selected := 0
	for index in presets.size():
		preset_dropdown.add_item(presets[index])
		if presets[index] == active:
			selected = index + 1
	preset_dropdown.select(selected)
	preset_dropdown.disabled = not compatible or presets.is_empty()


func _rebuild_curve() -> void:
	var temperatures: PackedFloat64Array = selected_fan.get_curve_temperatures()
	var percents: PackedInt32Array = selected_fan.get_curve_percents()
	if temperatures.size() != percents.size():
		return
	if _curve_matches(temperatures, percents):
		return
	_clear_curve_controls()
	for index in temperatures.size():
		var temperature := SLIDER_SCENE.instantiate() as ValueSlider
		temperature.name = "Point%dTemperature" % (index + 1)
		temperature.text = "Point %d temperature (C)" % (index + 1)
		temperature.min_value = selected_fan.get_minimum_valid_temperature_c()
		temperature.max_value = selected_fan.get_full_speed_temperature_c()
		temperature.step = 1.0
		temperature.value = temperatures[index]
		temperature.editable = compatible
		temperature.value_changed.connect(_on_curve_changed)
		curve_points.add_child(temperature)
		curve_temperature_sliders.append(temperature)

		var percent := SLIDER_SCENE.instantiate() as ValueSlider
		percent.name = "Point%dDuty" % (index + 1)
		percent.text = "Point %d fan (%%)" % (index + 1)
		percent.min_value = selected_fan.get_minimum_percent()
		percent.max_value = 100.0
		percent.step = 1.0
		percent.value = percents[index]
		percent.editable = compatible
		percent.value_changed.connect(_on_curve_changed)
		curve_points.add_child(percent)
		curve_percent_sliders.append(percent)


func _curve_matches(temperatures: PackedFloat64Array, percents: PackedInt32Array) -> bool:
	if temperatures.size() != curve_temperature_sliders.size():
		return false
	for index in temperatures.size():
		if not is_equal_approx(curve_temperature_sliders[index].value, temperatures[index]):
			return false
		if int(curve_percent_sliders[index].value) != percents[index]:
			return false
	return true


func _on_fan_selected(index: int) -> void:
	_select_fan(index)


func _on_mode_selected(index: int) -> void:
	if syncing or not compatible or not selected_fan:
		return
	var successful := false
	match index:
		0:
			successful = selected_fan.set_automatic()
		1:
			successful = selected_fan.set_manual(int(manual_slider.value))
		2:
			if curve_temperature_sliders.size() >= 2:
				successful = _send_curve()
			else:
				var temperatures: PackedFloat64Array = selected_fan.get_curve_temperatures()
				var percents: PackedInt32Array = selected_fan.get_curve_percents()
				if temperatures.size() >= 2 and temperatures.size() == percents.size():
					successful = selected_fan.set_curve(temperatures, percents)
				else:
					var initial := initial_curve(
						selected_fan.get_restart_temperature_c(),
						selected_fan.get_full_speed_temperature_c(),
						selected_fan.get_minimum_percent())
					successful = selected_fan.set_curve(
						initial.temperatures, initial.percents)
	_apply_result(successful)


func _on_preset_selected(index: int) -> void:
	if syncing or not compatible or not selected_fan:
		return
	if index == 0:
		_apply_result(_send_curve())
		return
	var presets: PackedStringArray = selected_fan.get_presets()
	if index - 1 < presets.size():
		_apply_result(selected_fan.apply_preset(presets[index - 1]))


func _on_manual_changed(_value: float) -> void:
	if syncing or not compatible or not selected_fan or selected_fan.get_mode() != "manual":
		return
	apply_timer.start()


func _on_curve_changed(_value: float) -> void:
	if syncing or not compatible or not selected_fan:
		return
	preset_dropdown.select(0)
	apply_timer.start()


func _apply_curve() -> void:
	if not compatible or not selected_fan:
		return
	if selected_fan.get_mode() == "manual":
		_apply_result(selected_fan.set_manual(int(manual_slider.value)))
		return
	if selected_fan.get_mode() in ["curve", "preset"]:
		_apply_result(_send_curve())


func _send_curve() -> bool:
	var temperatures := PackedFloat64Array()
	var percents := PackedInt32Array()
	for slider in curve_temperature_sliders:
		temperatures.append(slider.value)
	for slider in curve_percent_sliders:
		percents.append(int(slider.value))
	return selected_fan.set_curve(temperatures, percents)


func _apply_result(successful: bool) -> void:
	if not successful:
		status_label.text = "PowerStation rejected the change: %s" % selected_fan.get_last_error()
		return
	_sync_view.call_deferred()


func _on_service_stopped() -> void:
	fans = []
	_clear_selected_fan()
	compatible = false
	_set_card_available(false)


func _clear_selected_fan() -> void:
	apply_timer.stop()
	if selected_fan and selected_fan.updated.is_connected(_sync_view):
		selected_fan.updated.disconnect(_sync_view)
	selected_fan = null
	_clear_curve_controls()


func _clear_curve_controls() -> void:
	for child in curve_points.get_children():
		curve_points.remove_child(child)
		child.queue_free()
	curve_temperature_sliders.clear()
	curve_percent_sliders.clear()


func _set_card_available(available: bool) -> void:
	var card := find_parent("FanControlsCard") as Control
	if not card or card.visible == available:
		return
	card.visible = available
	var viewport := card.get_parent()
	if viewport and viewport.has_node("FocusGroup"):
		var outer_focus := viewport.get_node("FocusGroup") as FocusGroup
		outer_focus.recalculate_focus.call_deferred()


static func should_show_card(fan_count: int) -> bool:
	return fan_count > 0


static func should_show_selector(fan_count: int) -> bool:
	return fan_count > 1


static func supports_api_version(version: int) -> bool:
	return version == 1


static func initial_curve(
		restart_temperature_c: float,
		full_speed_temperature_c: float,
		minimum_percent: int,
	) -> Dictionary:
	return {
		"temperatures": PackedFloat64Array([
			restart_temperature_c,
			full_speed_temperature_c,
		]),
		"percents": PackedInt32Array([minimum_percent, 100]),
	}


static func mode_to_index(mode: String) -> int:
	match mode:
		"manual":
			return 1
		"curve", "preset":
			return 2
		_:
			return 0


static func describe_state(state: Dictionary) -> String:
	if not state.get("compatible", false):
		return "Incompatible PowerStation fan API. Update PowerStation."
	var fault := str(state.get("fault", ""))
	if not fault.is_empty():
		if state.get("automatic_verified", false):
			return "Automatic fallback: %s" % fault
		return "Fan fault: %s" % fault
	if state.get("suspended", false):
		return "Firmware automatic mode verified for sleep"
	if state.get("mode", "automatic") == "automatic":
		if state.get("automatic_verified", false):
			return "Firmware automatic mode"
		return "Waiting for firmware automatic verification"
	return "PowerStation is controlling the fan"


static func describe_limits(
		minimum_percent: int,
		minimum_running_percent: int,
		stop_temperature_c: float,
		restart_temperature_c: float,
		full_speed_temperature_c: float,
		emergency_handoff_temperature_c: float,
	) -> String:
	return "Duty %d-100%%  |  Running floor %d%%  |  Stop <= %.0f C / restart > %.0f C\nFull fan %.0f C  |  Firmware handoff %.0f C" % [
		minimum_percent,
		minimum_running_percent,
		stop_temperature_c,
		restart_temperature_c,
		full_speed_temperature_c,
		emergency_handoff_temperature_c,
	]


static func _display_backend(backend: String) -> String:
	match backend:
		"software_curve":
			return "Software curve"
		"hardware_curve":
			return "Hardware curve"
		_:
			return backend.capitalize()

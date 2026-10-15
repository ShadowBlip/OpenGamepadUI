extends VBoxContainer

const Model := preload("res://core/systems/performance/fan_profile_model.gd")
const MODE_LABELS := {"automatic": "Automatic", "manual": "Manual", "software_curve": "Software curve", "firmware_curve": "Firmware curve"}
@export var connect_backend := true
var power_station := load("res://core/systems/performance/power_station.tres") as PowerStationInstance
var model := Model.new()
var _syncing := false
var _selected := 0
var _modes: Array = []

@onready var focus_group := $%FocusGroup as FocusGroup
@onready var fan_dropdown := $%FanDropdown as Dropdown
@onready var mode_dropdown := $%ModeDropdown as Dropdown
@onready var manual_slider := $%ManualSlider as ValueSlider
@onready var telemetry_label := $%TelemetryLabel as Label
@onready var status_label := $%StatusLabel as Label
@onready var profile_label := $%ProfileLabel as Label
@onready var profile_editor := $%ProfileEditor as TextEdit
@onready var profile_file := $%ProfileFile as LineEdit
@onready var apply_button := $%ApplyButton as Button
@onready var automatic_button := $%AutomaticButton as Button

func _ready() -> void:
	model.updated.connect(_sync_view)
	fan_dropdown.item_selected.connect(_select_fan)
	mode_dropdown.item_selected.connect(_select_mode)
	manual_slider.value_changed.connect(_set_percent)
	$%ServiceTimer.timeout.connect(_refresh_devices)
	$%UseJsonButton.pressed.connect(_use_json)
	$%LoadFileButton.pressed.connect(func(): model.load_file(profile_file.text))
	apply_button.pressed.connect(_apply)
	automatic_button.pressed.connect(_automatic)
	if connect_backend:
		power_station.started.connect(_refresh_devices)
		power_station.stopped.connect(_refresh_devices)
		_refresh_devices()
	else:
		$%ServiceTimer.stop()
		_sync_view()

func _refresh_devices() -> void:
	if not connect_backend:
		return
	model.start(power_station.get_fan() if power_station else null)

func _select_fan(index: int) -> void:
	if _syncing:
		return
	_selected = index
	_sync_view()

func _select_mode(index: int) -> void:
	if _syncing or index < 0 or index >= _modes.size():
		return
	model.edit_fan(model.snapshot.fans[_selected].id, _modes[index], int(manual_slider.value))
	profile_editor.text = JSON.stringify(model.draft, "  ")

func _set_percent(value: float) -> void:
	if _syncing:
		return
	model.edit_fan(model.snapshot.fans[_selected].id, "manual", int(value))
	profile_editor.text = JSON.stringify(model.draft, "  ")

func _use_json() -> void:
	if model.set_json(profile_editor.text):
		profile_editor.text = JSON.stringify(model.draft, "  ")

func _apply() -> void:
	if model.set_json(profile_editor.text):
		model.apply()

func _automatic() -> void:
	model.automatic()
	profile_editor.text = JSON.stringify(model.draft, "  ")

func _sync_view() -> void:
	if not is_node_ready():
		return
	_syncing = true
	var state := model.snapshot
	var fans: Array = state.get("fans", [])
	var available := model.compatible() and not fans.is_empty()
	var card := get_parent() as Control
	if card and card.name == "FanControlsCard":
		card.visible = available or not str(state.get("error", "")).is_empty()
	fan_dropdown.clear()
	for fan in fans:
		fan_dropdown.add_item(str(fan.name))
	_selected = clampi(_selected, 0, maxi(0, fans.size() - 1))
	fan_dropdown.select(_selected)
	fan_dropdown.visible = fans.size() > 1
	mode_dropdown.clear()
	_modes.clear()
	var lines: Array[String] = []
	if available and _selected < model.draft.get("fans", []).size():
		var fan: Dictionary = fans[_selected]
		var entry: Dictionary = model.draft.fans[_selected]
		# Profiles may list fans in a different order to enumeration.
		for candidate in model.draft.fans:
			if candidate.fan == fan.id:
				entry = candidate
				break
		for mode in fan.available_modes:
			if MODE_LABELS.has(mode):
				_modes.append(mode)
				mode_dropdown.add_item(MODE_LABELS[mode])
		mode_dropdown.select(_modes.find(entry.mode))
		manual_slider.visible = entry.mode == "manual"
		manual_slider.value = entry.get("percent", 60)
		var duty := "%d%%" % int(fan.percent) if fan.percent_valid else "percentage unavailable"
		lines.append("Current: %s — %s" % [MODE_LABELS.get(fan.mode, fan.mode), duty])
		if not str(fan.fault).is_empty():
			lines.append("Fan fault: " + str(fan.fault))
	else:
		manual_slider.visible = false
	for sensor in state.get("sensors", []):
		lines.append("%s: %.1f C (%s)" % [sensor.name, float(sensor.temperature_c), sensor.id] if sensor.telemetry_valid else "%s: temperature unavailable (%s)" % [sensor.name, sensor.id])
	telemetry_label.text = "\n".join(lines) if not lines.is_empty() else "Fan telemetry unavailable"
	profile_label.text = "Current profile: %s\n%s" % [state.get("profile_name", "") if not str(state.get("profile_name", "")).is_empty() else "Firmware Automatic", state.get("profile_path", "")]
	status_label.text = model.error if not model.error.is_empty() else str(state.get("error", "Edit a complete profile, then Apply. New service processes start Automatic."))
	mode_dropdown.disabled = not available
	manual_slider.editable = available
	apply_button.disabled = not available
	automatic_button.disabled = not available
	$%LoadFileButton.disabled = not available
	$%UseJsonButton.disabled = not available
	if profile_editor.text.is_empty() and not model.draft.is_empty():
		profile_editor.text = JSON.stringify(model.draft, "  ")
	_syncing = false
	focus_group.recalculate_focus.call_deferred()

extends VBoxContainer
## The shared resource keeps drafts and requests alive across quick-menu remounts.
@export var model: LightingModel = preload("res://core/systems/input/lighting_model.tres")
@export var connect_backend := true
var _updating := false
var _effects: Array[String] = []
var _ids: Array = []
var _last_focus: Control

@onready var device: Dropdown = $Device
@onready var effect: Dropdown = $Effect
@onready var red: ValueSlider = $Red
@onready var green: ValueSlider = $Green
@onready var blue: ValueSlider = $Blue
@onready var brightness: ValueSlider = $Brightness
@onready var cycle: ValueSlider = $Cycle
@onready var apply_button: Button = $Apply
@onready var off_button: Button = $Off
@onready var status: Label = $Status
@onready var breathing_note: Label = $BreathingNote

func _ready() -> void:
	if connect_backend:
		model.start(load("res://core/systems/input/input_plumber.tres"))
	model.updated.connect(_refresh)
	device.item_selected.connect(_select_device)
	effect.item_selected.connect(_select_effect)
	red.value_changed.connect(_edit_color.bind(0))
	green.value_changed.connect(_edit_color.bind(1))
	blue.value_changed.connect(_edit_color.bind(2))
	brightness.value_changed.connect(_edit_number.bind("brightness", 1))
	cycle.value_changed.connect(_edit_number.bind("cycle_period_ms", 1000))
	apply_button.pressed.connect(model.apply)
	off_button.pressed.connect(model.apply.bind(true))
	focus_entered.connect(_grab_inner_focus)
	visibility_changed.connect(_update_focus)
	_refresh()

func _exit_tree() -> void:
	if model.updated.is_connected(_refresh):
		model.updated.disconnect(_refresh)

func _select_device(index: int) -> void:
	if not _updating and index >= 0 and index < _ids.size():
		model.select_device(str(_ids[index]))

func _select_effect(index: int) -> void:
	if not _updating and index >= 0 and index < _effects.size():
		model.edit("effect", _effects[index])

func _edit_color(value: float, index: int) -> void:
	if _updating or model.current().is_empty():
		return
	var color: Array = model.current().draft.color.duplicate()
	color[index] = int(value)
	model.edit("color", color)

func _edit_number(value: float, field: String, factor: int) -> void:
	if not _updating:
		model.edit(field, int(value * factor))

func _refresh() -> void:
	if not is_node_ready():
		return
	_updating = true
	var entry := model.current()
	var available: bool = not entry.is_empty() and entry.snapshot.get("available", false)
	var busy: bool = not entry.is_empty() and entry.busy
	status.text = model.status_text()
	_ids = model.entries.keys()
	device.visible = _ids.size() > 1
	device.clear()
	for key in _ids:
		device.add_item(str(key).replace("-", " ").capitalize())
	device.select(_ids.find(model.selected_id))
	device.disabled = busy
	_effects.clear()
	if available:
		for name in entry.snapshot.effects:
			if LightingModel.EFFECT_LABELS.has(name):
				_effects.append(name)
	effect.clear()
	for name in _effects:
		effect.add_item(LightingModel.EFFECT_LABELS[name])
	effect.visible = available
	effect.disabled = busy
	var draft: Dictionary = entry.get("draft", LightingModel.DEFAULT_CONFIG)
	var supported := str(draft.effect) in _effects
	effect.select(_effects.find(str(draft.effect)))
	var colored: bool = available and supported and draft.effect in ["solid", "breathing"]
	for slider in [red, green, blue]:
		slider.visible = colored
		slider.editable = not busy
	red.value = int(draft.color[0])
	green.value = int(draft.color[1])
	blue.value = int(draft.color[2])
	brightness.visible = available and supported and draft.effect != "off"
	brightness.editable = not busy
	brightness.value = int(draft.brightness)
	cycle.visible = available and supported and draft.effect == "cycle"
	cycle.editable = not busy
	cycle.min_value = float(entry.get("snapshot", {}).get("cycle_min_ms", 2000)) / 1000.0
	cycle.max_value = float(entry.get("snapshot", {}).get("cycle_max_ms", 30000)) / 1000.0
	cycle.value = float(draft.cycle_period_ms) / 1000.0
	breathing_note.visible = available and supported and draft.effect == "breathing"
	apply_button.visible = available
	off_button.visible = available and "off" in _effects
	apply_button.disabled = busy or not supported
	off_button.disabled = busy
	_updating = false
	_update_focus.call_deferred()

func _focus_controls() -> Array[Control]:
	var controls: Array[Control] = []
	if device.visible and not device.disabled:
		controls.append(device.option_button)
	if effect.visible and not effect.disabled:
		controls.append(effect.option_button)
	for slider in [red, green, blue, brightness, cycle]:
		if slider.visible and slider.editable:
			controls.append(slider.slider)
	for button in [apply_button, off_button]:
		if button.visible and not button.disabled:
			controls.append(button)
	return controls

func _update_focus() -> void:
	if not is_node_ready() or not is_inside_tree():
		return
	var controls := _focus_controls()
	for i in controls.size():
		var control := controls[i]
		var previous: NodePath = controls[i - 1].get_path() if i > 0 else focus_neighbor_top
		var next: NodePath = controls[i + 1].get_path() if i + 1 < controls.size() else focus_neighbor_bottom
		control.focus_neighbor_top = previous
		control.focus_previous = previous
		control.focus_neighbor_bottom = next
		control.focus_next = next
		if not control.focus_entered.is_connected(_remember_focus.bind(control)):
			control.focus_entered.connect(_remember_focus.bind(control))
	if is_instance_valid(_last_focus) and not _last_focus in controls and _last_focus.has_focus():
		_grab_inner_focus()

func _remember_focus(control: Control) -> void:
	_last_focus = control

func _grab_inner_focus() -> void:
	var controls := _focus_controls()
	if is_instance_valid(_last_focus) and _last_focus in controls:
		_last_focus.grab_focus()
	elif not controls.is_empty():
		controls[0].grab_focus()

# FocusGroup updates the wrapper after it has entered the tree.
func _set(property: StringName, _value: Variant) -> bool:
	if property.begins_with("focus_") and is_node_ready():
		_update_focus.call_deferred()
	return false

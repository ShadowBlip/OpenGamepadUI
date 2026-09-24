extends Resource
class_name LightingModel
## Shared settings and drafts. Only InputPlumber owns effects or persistence.
signal updated

const EFFECT_LABELS := {"off": "Off", "solid": "Solid colour", "breathing": "Breathing", "cycle": "Colour cycle"}
const DEFAULT_CONFIG := {"effect": "off", "color": [255, 255, 255], "brightness": 30, "cycle_period_ms": 8000}
var entries: Dictionary = {}
var selected_id: String = ""
var _instance: Object
var _sources: Array = []

func start(instance: Object) -> void:
	if _instance == instance:
		return
	if _instance:
		_instance.led_device_added.disconnect(_on_device_added)
		_instance.led_device_removed.disconnect(_on_device_removed)
	_instance = instance
	_instance.led_device_added.connect(_on_device_added, CONNECT_DEFERRED)
	_instance.led_device_removed.connect(_on_device_removed, CONNECT_DEFERRED)
	set_sources(_instance.get_led_devices())

func _on_device_added(_device: Object) -> void:
	set_sources(_instance.get_led_devices())

func _on_device_removed(_path: String) -> void:
	set_sources(_instance.get_led_devices())

## Injectable source boundary also used by the headless regression tests.
func set_sources(sources: Array) -> void:
	for source in _sources:
		if source in sources:
			continue
		source.lighting_changed.disconnect(_on_source_changed.bind(source))
		source.apply_finished.disconnect(_on_apply_finished.bind(source))
		for key in entries:
			var entry: Dictionary = entries[key]
			if entry.source != source:
				continue
			entry.source = null
			entry.snapshot.available = false
			entry.snapshot.error = "Lighting device disconnected."
			if entry.busy:
				entry.error = "Device disconnected; check the saved settings before retrying."
			entry.busy = false
	for source in sources:
		if source not in _sources:
			source.lighting_changed.connect(_on_source_changed.bind(source), CONNECT_DEFERRED)
			source.apply_finished.connect(_on_apply_finished.bind(source), CONNECT_DEFERRED)
	_sources = sources.duplicate()
	for source in _sources:
		_on_source_changed(source)
	updated.emit()

func _on_source_changed(source: Object) -> void:
	if source not in _sources:
		return
	var snapshot: Dictionary = source.get_snapshot()
	var key: String = snapshot.get("persistent_id", "")
	if key.is_empty():
		updated.emit()
		return
	if not entries.has(key):
		entries[key] = {"source": source, "snapshot": snapshot, "draft": DEFAULT_CONFIG.duplicate(true),
			"dirty": false, "busy": false, "error": "", "edits": 0, "submitted_edits": -1, "request": 0}
	var entry: Dictionary = entries[key]
	# Duplicate persistent IDs cannot be safely controlled as one device.
	for other in _sources:
		if other != source and str(other.get_snapshot().get("persistent_id", "")) == key:
			entry.snapshot.available = false
			entry.snapshot.error = "More than one lighting device has this identity."
			updated.emit()
			return
	entry.source = source
	entry.snapshot = snapshot.duplicate(true)
	if not entry.dirty and snapshot.has("config"):
		entry.draft = snapshot.config.duplicate(true)
	if selected_id.is_empty():
		selected_id = key
	updated.emit()

func select_device(key: String) -> void:
	if entries.has(key):
		selected_id = key
		updated.emit()

func current() -> Dictionary:
	return entries.get(selected_id, {})

func edit(field: String, value: Variant) -> void:
	var entry := current()
	if entry.is_empty() or not DEFAULT_CONFIG.has(field):
		return
	entry.draft[field] = value.duplicate() if value is Array else value
	entry.edits += 1
	entry.dirty = true
	entry.error = ""
	updated.emit()

func apply(turn_off: bool = false) -> void:
	var entry := current()
	if entry.is_empty() or entry.busy or not entry.source or not entry.snapshot.get("available", false):
		return
	if turn_off:
		entry.draft.effect = "off"
		entry.edits += 1
		entry.dirty = true
	var draft: Dictionary = entry.draft
	entry.error = ""
	var request: int = entry.source.apply_config(draft.effect, PackedByteArray(draft.color), int(draft.brightness), int(draft.cycle_period_ms))
	if request <= 0:
		entry.error = "These lighting settings are unavailable. Refresh and try again."
	else:
		entry.busy = true
		entry.request = request
		entry.submitted_edits = entry.edits
	updated.emit()

func _on_apply_finished(request: int, success: bool, error: String, source: Object) -> void:
	for key in entries:
		var entry: Dictionary = entries[key]
		if entry.source != source or not entry.busy or entry.request != request:
			continue
		entry.busy = false
		entry.error = error
		if success:
			entry.snapshot = source.get_snapshot().duplicate(true)
			if entry.edits == entry.submitted_edits:
				entry.dirty = false
				entry.draft = entry.snapshot.config.duplicate(true)
		updated.emit()
		return

func status_text() -> String:
	var entry := current()
	if entry.is_empty():
		for source in _sources:
			var state: Dictionary = source.get_snapshot()
			if not str(state.get("error", "")).is_empty():
				return str(state.error)
		return "Joystick lighting is unavailable. A supported device and InputPlumber lighting support are required."
	if not str(entry.error).is_empty():
		return str(entry.error)
	if entry.busy:
		return "Saving lighting settings..."
	var snapshot: Dictionary = entry.snapshot
	if not snapshot.get("available", false):
		return str(snapshot.get("error", "Lighting controls are unavailable."))
	if snapshot.status == "failed":
		return "Settings are saved, but lighting could not be applied. %s Use Apply lighting to retry." % snapshot.get("error", "")
	if snapshot.status == "unavailable":
		return "Settings are saved. The lighting device is unavailable. %s" % snapshot.get("error", "")
	if snapshot.status == "pending":
		return "Settings are saved. Waiting for the lighting device."
	if entry.dirty:
		return "You have unapplied changes."
	return "Lighting settings applied."

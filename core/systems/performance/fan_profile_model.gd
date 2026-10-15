extends Resource
class_name FanProfileModel
## Drafts are application preferences. PowerStation owns hardware validation and safety.
signal updated

const API_VERSION := 2
const MAX_PROFILE_BYTES := 65536
var backend: Object
var snapshot: Dictionary = {}
var draft: Dictionary = {}
var error := ""
var _loaded_preferences := false

func start(collection: Object) -> void:
	backend = collection
	refresh()

func refresh() -> void:
	if not backend:
		snapshot = {"available": false, "fans": [], "sensors": [], "error": "PowerStation is unavailable."}
	else:
		var state: Variant = JSON.parse_string(backend.get_snapshot_json())
		snapshot = state if state is Dictionary else {"available": false, "fans": [], "sensors": [], "error": "Invalid fan service response."}
	if compatible() and not _loaded_preferences:
		_loaded_preferences = true
		draft = automatic_profile(snapshot.fans)
		var saved: Variant = JSON.parse_string(backend.get_saved_selection_json())
		if saved is Dictionary and saved.get("kind") == "json" and saved.get("profile") is Dictionary:
			if validate_profile(saved.profile, snapshot).is_empty():
				draft = _canonical_profile(saved.profile)
			else:
				error = "Saved fan profile no longer matches the hardware. Select or edit a complete profile."
		var saved_error: String = backend.get_last_error()
		if not saved_error.is_empty():
			error = saved_error
	updated.emit()

func compatible() -> bool:
	return snapshot.get("available", false) and snapshot.get("api_version", 0) == API_VERSION

static func automatic_profile(fans: Array) -> Dictionary:
	var entries: Array = []
	for fan in fans:
		entries.append({"fan": fan.id, "mode": "automatic"})
	return {"name": "OpenGamepadUI", "fans": entries}

func set_json(raw: String) -> bool:
	if raw.to_utf8_buffer().size() > MAX_PROFILE_BYTES:
		error = "Fan profiles must be at most 64 KiB."
		updated.emit()
		return false
	var profile: Variant = JSON.parse_string(raw)
	error = validate_profile(profile, snapshot)
	if error.is_empty():
		draft = _canonical_profile(profile)
	updated.emit()
	return error.is_empty()

func apply() -> bool:
	error = validate_profile(draft, snapshot)
	if not compatible():
		error = "PowerStation fan API v2 is required."
	if not error.is_empty():
		updated.emit()
		return false
	var success: bool = backend.load_profile_json(JSON.stringify(draft), snapshot.get("owner", ""))
	error = "" if success else str(backend.get_last_error())
	refresh()
	return success

func automatic() -> bool:
	if not compatible():
		return false
	# An explicit Automatic action never depends on sensor validity or a saved draft.
	var previous := draft.duplicate(true)
	draft = automatic_profile(snapshot.fans)
	if apply():
		return true
	draft = previous
	updated.emit()
	return false

func load_file(file: String) -> bool:
	if not compatible():
		return false
	var success: bool = backend.load_profile(file, snapshot.get("owner", ""))
	error = "" if success else str(backend.get_last_error())
	refresh()
	return success

func edit_fan(id: String, mode: String, percent: int = 60) -> void:
	if not draft.get("fans") is Array:
		return
	var index := -1
	for candidate in draft.fans.size():
		if draft.fans[candidate].fan == id:
			index = candidate
			break
	if index < 0:
		return
	var entry: Dictionary = {"fan": draft.fans[index].fan, "mode": mode}
	if mode == "manual":
		entry.percent = percent
	if mode in ["software_curve", "firmware_curve"]:
		# The user supplies sensor IDs and the complete curve in the JSON editor.
		# Native point counts and trusted safety policy are never guessed here.
		var previous: Dictionary = draft.fans[index]
		entry.sensors = previous.get("sensors", []).duplicate()
		entry.curve = previous.get("curve", []).duplicate(true)
	draft.fans[index] = entry
	error = ""
	updated.emit()

static func validate_profile(profile: Variant, state: Dictionary) -> String:
	if not profile is Dictionary or profile.size() != 2 or not profile.get("name") is String or str(profile.name).strip_edges().is_empty() or not profile.get("fans") is Array:
		return "Use a profile name and a fans array."
	var fans: Array = state.get("fans", [])
	if fans.is_empty() or profile.fans.size() != fans.size():
		return "A profile must contain every available fan exactly once."
	var known: Dictionary = {}
	for fan in fans:
		known[fan.id] = fan
	var sensors: Array = []
	for sensor in state.get("sensors", []):
		sensors.append(sensor.id)
	var seen: Array = []
	for entry in profile.fans:
		if not entry is Dictionary or not entry.get("fan") is String or not known.has(entry.fan) or entry.fan in seen:
			return "Unknown or duplicate fan ID."
		seen.append(entry.fan)
		if not entry.get("mode") is String or entry.mode not in known[entry.fan].available_modes:
			return "Select a mode advertised by this fan."
		var fields: Array = ["fan", "mode"]
		match entry.mode:
			"manual":
				fields.append("percent")
				if not _percent(entry.get("percent")):
					return "Manual percentage must be an integer from 0 to 100."
			"software_curve", "firmware_curve":
				fields.append_array(["sensors", "curve"])
				if not entry.get("sensors") is Array or entry.sensors.is_empty():
					return "A curve needs sensor IDs from the available sensor list."
				var seen_sensors: Array = []
				for id in entry.sensors:
					if id not in sensors or id in seen_sensors:
						return "Unknown or duplicate sensor ID."
					seen_sensors.append(id)
				if not entry.get("curve") is Array or entry.curve.size() < 2:
					return "Supply the complete temperature/percentage curve with at least two points."
				var previous_temperature := -INF
				var previous_percent := -1
				for point in entry.curve:
					if not point is Array or point.size() != 2 or not (point[0] is int or point[0] is float) or not is_finite(float(point[0])) or float(point[0]) <= previous_temperature or not _percent(point[1]) or int(point[1]) < previous_percent:
						return "Curve temperatures must increase and percentages must not decrease."
					previous_temperature = float(point[0])
					previous_percent = int(point[1])
		for key in entry:
			if key not in fields:
				return "Profile fields cannot contain hardware paths or controller policy."
	return ""

static func _percent(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= 0 and float(value) <= 100

static func _canonical_profile(profile: Dictionary) -> Dictionary:
	var result := profile.duplicate(true)
	for entry in result.fans:
		if entry.mode == "manual":
			entry.percent = int(entry.percent)
		if entry.mode in ["software_curve", "firmware_curve"]:
			for point in entry.curve:
				point[1] = int(point[1])
	return result

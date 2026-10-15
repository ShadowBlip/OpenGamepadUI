extends GutTest
const Model := preload("res://core/systems/performance/fan_profile_model.gd")

class Backend extends RefCounted:
	var state: Dictionary = {"available": true, "api_version": 2, "owner": ":1.8", "profile_name": "", "profile_path": "",
		"fans": [{"id": "test/fan", "name": "Fan", "mode": "automatic", "available_modes": ["automatic", "manual", "software_curve"], "percent": 0, "percent_valid": false, "fault": ""}],
		"sensors": [{"id": "test/fan/cpu", "name": "CPU", "temperature_c": 50.0, "telemetry_valid": true}]}
	var calls: Array = []
	var saved: Dictionary = {}
	var error := ""
	var denied := false
	func get_snapshot_json() -> String:
		return JSON.stringify(state)
	func get_saved_selection_json() -> String:
		return JSON.stringify(saved)
	func get_last_error() -> String:
		return error
	func load_profile_json(raw: String, owner: String) -> bool:
		calls.append({"profile": JSON.parse_string(raw), "owner": owner})
		if denied:
			error = "Not applied; sensor unavailable"
			return false
		saved = {"kind": "json", "profile": JSON.parse_string(raw)}
		state.profile_name = saved.profile.name
		error = ""
		return true
	func load_profile(file: String, owner: String) -> bool:
		calls.append({"file": file, "owner": owner})
		return not denied

var backend: Backend
var model: FanProfileModel
func before_each() -> void:
	backend = Backend.new()
	model = Model.new()
	model.start(backend)

func test_first_use_and_refresh_never_send_a_profile() -> void:
	model.refresh()
	assert_eq(backend.calls.size(), 0)
	assert_eq(model.draft.fans[0].mode, "automatic")
	assert_true(model.compatible())

func test_explicit_manual_uses_complete_profile_and_displayed_owner() -> void:
	model.edit_fan("test/fan", "manual", 60)
	assert_eq(backend.calls.size(), 0)
	assert_true(model.apply())
	assert_eq(backend.calls[0].owner, ":1.8")
	assert_eq(backend.calls[0].profile.fans, [{"fan": "test/fan", "mode": "manual", "percent": 60.0}])

func test_automatic_works_without_telemetry_and_with_an_invalid_draft() -> void:
	backend.state.sensors[0].telemetry_valid = false
	model.draft = {"bad": "input"}
	assert_true(model.automatic())
	assert_eq(backend.calls[0].profile.fans[0], {"fan": "test/fan", "mode": "automatic"})

func test_failed_apply_preserves_draft_and_reports_error() -> void:
	model.edit_fan("test/fan", "manual", 60)
	backend.denied = true
	assert_false(model.apply())
	assert_eq(model.draft.fans[0].percent, 60)
	assert_string_contains(model.error, "sensor unavailable")
	assert_true(backend.saved.is_empty())

func test_service_restart_refresh_does_not_replay_the_draft() -> void:
	model.edit_fan("test/fan", "manual", 60)
	backend.state.owner = ":1.9"
	model.refresh()
	assert_eq(backend.calls.size(), 0)
	assert_eq(model.draft.fans[0].percent, 60)

func test_complete_sensor_curve_is_accepted_without_inventing_native_limits() -> void:
	var profile := {"name": "Custom", "fans": [{"fan": "test/fan", "mode": "software_curve", "sensors": ["test/fan/cpu"], "curve": [[45, 20], [95, 100]]}]}
	assert_true(model.set_json(JSON.stringify(profile)))
	assert_true(model.apply())
	assert_eq(backend.calls[0].profile.fans[0].sensors, ["test/fan/cpu"])

func test_unknown_duplicate_unsupported_and_incomplete_profiles_are_rejected() -> void:
	var profile := Model.automatic_profile(backend.state.fans)
	profile.fans[0].fan = "unknown"
	assert_ne(Model.validate_profile(profile, backend.state), "")
	profile = Model.automatic_profile(backend.state.fans)
	profile.fans.append(profile.fans[0].duplicate())
	assert_ne(Model.validate_profile(profile, backend.state), "")
	profile.fans = []
	assert_ne(Model.validate_profile(profile, backend.state), "")
	profile = Model.automatic_profile(backend.state.fans)
	profile.fans[0].mode = "firmware_curve"
	assert_ne(Model.validate_profile(profile, backend.state), "")

func test_untrusted_paths_policy_invalid_percentages_and_curves_never_write() -> void:
	for percent in [-1, 101, 12.5, "60"]:
		assert_false(model.set_json(JSON.stringify({"name": "Bad", "fans": [{"fan": "test/fan", "mode": "manual", "percent": percent}]})))
	for curve in [[[50, 20], [50, 100]], [[50, 60], [95, 20]], [[50, 20]], [[50, 20], [95, 101]]]:
		assert_false(model.set_json(JSON.stringify({"name": "Bad", "fans": [{"fan": "test/fan", "mode": "software_curve", "sensors": ["test/fan/cpu"], "curve": curve}]})))
	assert_false(model.set_json(JSON.stringify({"name": "Bad", "fans": [{"fan": "test/fan", "mode": "automatic", "sysfs": "/sys/fake"}]})))
	assert_eq(backend.calls.size(), 0)

func test_unknown_duplicate_sensors_and_bad_json_leave_the_draft_intact() -> void:
	var previous := model.draft.duplicate(true)
	for sensors in [["missing"], ["test/fan/cpu", "test/fan/cpu"], []]:
		assert_false(model.set_json(JSON.stringify({"name": "Bad", "fans": [{"fan": "test/fan", "mode": "software_curve", "sensors": sensors, "curve": [[45, 20], [95, 100]]}]})))
	assert_false(model.set_json("{"))
	assert_eq(model.draft, previous)

func test_v1_future_and_disconnected_services_cannot_apply() -> void:
	for version in [1, 3]:
		backend.state.api_version = version
		model.refresh()
		assert_false(model.compatible())
		assert_false(model.apply())
	assert_eq(backend.calls.size(), 0)

func test_fan_edits_use_ids_when_profile_order_differs() -> void:
	backend.state.fans.append({"id": "test/other", "available_modes": ["automatic", "manual"]})
	model.draft = {"name": "Two", "fans": [{"fan": "test/other", "mode": "automatic"}, {"fan": "test/fan", "mode": "automatic"}]}
	model.edit_fan("test/fan", "manual", 65)
	assert_eq(model.draft.fans[0].mode, "automatic")
	assert_eq(model.draft.fans[1].percent, 65)

func test_saved_json_loads_as_an_editable_draft_without_reapplying() -> void:
	backend.saved = {"kind": "json", "profile": {"name": "Saved", "fans": [{"fan": "test/fan", "mode": "manual", "percent": 60}]}}
	model = Model.new()
	model.start(backend)
	assert_eq(backend.calls.size(), 0)
	assert_eq(model.draft.name, "Saved")
	assert_true(model.draft.fans[0].percent is int)
	assert_true(model.apply())

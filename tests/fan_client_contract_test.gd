extends SceneTree
## Run only against the private fake-hardware service described in docs/fans.md.
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	if OS.get_environment("OGUI_FAN_PRIVATE_FIXTURE") != "1" or not OS.get_environment("DBUS_SYSTEM_BUS_ADDRESS").begins_with("unix:"):
		push_error("This test requires an explicitly isolated private D-Bus/fake-sysfs fixture")
		quit(2)
		return
	var profile := {"name": "Restored", "fans": [{"fan": "ayaneo-3/system", "mode": "manual", "percent": 60}]}
	var selection := {"kind": "json", "profile": profile}
	if OS.get_environment("OGUI_FAN_SAVED_FILE") == "1":
		selection = {"kind": "file", "file": "quiet.yaml"}
	DirAccess.make_dir_recursive_absolute("user://data/fans")
	var saved := FileAccess.open("user://data/fans/profile.json", FileAccess.WRITE)
	saved.store_string(JSON.stringify({"version": 1, "selection": selection}))
	saved.close()
	check(OS.execute("chmod", ["600", ProjectSettings.globalize_path("user://data/fans/profile.json")]) == 0, "private fixture preference permissions")
	var instance := PowerStationInstance.new()
	var fan := instance.get_fan()
	var before: Dictionary = JSON.parse_string(fan.get_snapshot_json())
	check(before.get("available", false), "API v2 service is available")
	if not before.get("available", false):
		quit(1)
		return
	check(before.startup.eligible, "first native invocation is eligible")
	check(before.fans.size() == 1 and before.sensors.size() == 1, "fan/sensor discovery")
	check(fan.restore_saved(), "guarded restore succeeds through Godot and real native D-Bus")
	var restored: Dictionary = JSON.parse_string(fan.get_snapshot_json())
	check(not restored.startup.eligible, "native eligibility is consumed")
	check(restored.fans[0].percent_valid, "software duty has explicit validity")
	if selection.kind == "json":
		check(restored.profile_name == "Restored" and int(restored.fans[0].percent) == 60, "saved JSON restored as Manual 60")
	else:
		check(restored.profile_name == "Quiet" and restored.fans[0].mode == "software_curve", "saved file restored through native override-aware loading")
	check(not fan.restore_saved(), "the application does not attempt a second restoration")
	check(not fan.load_profile_json(" ".repeat(65537), restored.owner), "oversized JSON is rejected before parsing or writing")
	check(JSON.parse_string(fan.get_snapshot_json()).profile_name == restored.profile_name, "oversized input preserves the live native profile")
	var model := FanProfileModel.new()
	model.start(fan)
	check(model.set_json('{"name":"Edited","fans":[{"fan":"ayaneo-3/system","mode":"manual","percent":65}]}'), "JSON editor accepts integral percentages")
	check(model.apply(), "Godot JSON numeric serialization is accepted by native profile parsing")
	var edited: Dictionary = JSON.parse_string(fan.get_snapshot_json())
	check(edited.profile_name == "Edited" and int(edited.fans[0].percent) == 65, "native state confirms edited profile")
	check(model.automatic(), "explicit Automatic remains available")
	var automatic: Dictionary = JSON.parse_string(fan.get_snapshot_json())
	check(automatic.fans[0].mode == "automatic" and not automatic.fans[0].percent_valid, "firmware duty is not invented")
	print("FAN CONTRACT: %d assertions, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

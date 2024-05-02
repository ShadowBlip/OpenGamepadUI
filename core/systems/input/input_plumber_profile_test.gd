extends GutTest


func test_load() -> void:
	var profile := InputPlumberProfile.load("res://assets/gamepad/profiles/default.json")
	assert_eq(profile.name, "Default")


func test_save() -> void:
	var profile := InputPlumberProfile.load("res://assets/gamepad/profiles/default.json")
	profile.name = "Test Profile"
	assert_eq(profile.save("/tmp/test_profile.json"), OK)
	var loaded_profile := InputPlumberProfile.load("/tmp/test_profile.json")
	assert_eq(loaded_profile.name, "Test Profile")

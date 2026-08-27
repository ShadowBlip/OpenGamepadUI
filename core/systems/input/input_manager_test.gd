extends GutTest


# Test that the default input manager makes no assumptions about the target
# gamepad, leaving whatever target InputPlumber already configured in place.
func test_get_default_target_gamepad() -> void:
	var input_manager := InputManager.new()
	assert_eq(input_manager.get_default_target_gamepad(), "", "should not default to any target gamepad")
	input_manager.free()


# Test that overlay mode only assumes a target gamepad when Steam is the
# underlay process, so games running under Steam see the same controller they
# would on a Deck while other underlays keep whatever is already configured.
func test_get_default_target_gamepad_overlay_mode() -> void:
	var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
	var was_underlay := launch_manager.steam_is_underlay
	var input_manager := OverlayInputManager.new()

	launch_manager.steam_is_underlay = false
	assert_eq(input_manager.get_default_target_gamepad(), "", "should not default to any target gamepad without Steam")

	launch_manager.steam_is_underlay = true
	assert_eq(input_manager.get_default_target_gamepad(), "deck-uhid", "should default to the Steam Deck target gamepad under Steam")

	launch_manager.steam_is_underlay = was_underlay
	input_manager.free()

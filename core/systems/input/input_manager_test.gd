extends GutTest


# Test that the default input manager makes no assumptions about the target
# gamepad, leaving whatever target InputPlumber already configured in place.
func test_get_default_target_gamepad() -> void:
	var input_manager := InputManager.new()
	assert_eq(input_manager.get_default_target_gamepad(), "", "should not default to any target gamepad")
	input_manager.free()


# Test that overlay mode only assumes a target gamepad when Steam Input is in
# use, so games running under Steam see the same controller they would on a
# Deck while other sessions keep whatever is already configured.
func test_get_default_target_gamepad_overlay_mode() -> void:
	var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
	var was_steam_input := launch_manager.steam_input_enabled
	var input_manager := OverlayInputManager.new()

	launch_manager.steam_input_enabled = false
	assert_eq(input_manager.get_default_target_gamepad(), "", "should not default to any target gamepad without Steam Input")

	launch_manager.steam_input_enabled = true
	assert_eq(input_manager.get_default_target_gamepad(), "deck-uhid", "should default to the Steam Deck target gamepad under Steam Input")

	launch_manager.steam_input_enabled = was_steam_input
	input_manager.free()

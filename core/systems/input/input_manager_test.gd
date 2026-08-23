extends GutTest


# Test that the default input manager makes no assumptions about the target
# gamepad, leaving whatever target InputPlumber already configured in place.
func test_get_default_target_gamepad() -> void:
	var input_manager := InputManager.new()
	assert_eq(input_manager.get_default_target_gamepad(), "", "should not default to any target gamepad")
	input_manager.free()


# Test that overlay mode emulates a Steam Deck controller by default, so games
# running under the underlay see the same controller they would on a Deck.
func test_get_default_target_gamepad_overlay_mode() -> void:
	var input_manager := OverlayInputManager.new()
	assert_eq(input_manager.get_default_target_gamepad(), "deck-uhid", "should default to the Steam Deck target gamepad")
	input_manager.free()

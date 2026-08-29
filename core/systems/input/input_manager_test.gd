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
	var platform := load("res://core/global/platform.tres") as Platform
	var was_steam_input := launch_manager.steam_input_enabled
	var was_platform := platform.platform
	var input_manager := OverlayInputManager.new()
	platform.platform = null

	launch_manager.steam_input_enabled = false
	assert_eq(input_manager.get_default_target_gamepad(), "", "should not default to any target gamepad without Steam Input")

	launch_manager.steam_input_enabled = true
	assert_eq(input_manager.get_default_target_gamepad(), "deck-uhid", "should default to the Steam Deck target gamepad under Steam Input")

	platform.platform = was_platform
	launch_manager.steam_input_enabled = was_steam_input
	input_manager.free()


# Test that a platform can override the default target gamepad. Devices without
# a dedicated Quick Access Menu button need this, as Steam ignores the guide
# button chords on the Steam Deck target and leaves no way to open the QAM.
func test_get_default_target_gamepad_platform_override() -> void:
	var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
	var platform := load("res://core/global/platform.tres") as Platform
	var was_steam_input := launch_manager.steam_input_enabled
	var was_platform := platform.platform
	var input_manager := OverlayInputManager.new()

	var provider := PlatformProvider.new()
	provider.target_gamepad_override = "xbox-elite"
	platform.platform = provider

	launch_manager.steam_input_enabled = true
	assert_eq(input_manager.get_default_target_gamepad(), "xbox-elite", "should use the target gamepad the platform asked for")

	launch_manager.steam_input_enabled = false
	assert_eq(input_manager.get_default_target_gamepad(), "", "should not default to any target gamepad without Steam Input")

	platform.platform = was_platform
	launch_manager.steam_input_enabled = was_steam_input
	input_manager.free()

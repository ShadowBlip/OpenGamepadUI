extends GutTest

const FanControlsMenu := preload("res://core/ui/common/quick_bar/fan_controls_menu.gd")
const MENU_SCENE := preload("res://core/ui/common/quick_bar/fan_controls_menu.tscn")


func test_visibility_rules_cover_no_and_multiple_fans() -> void:
	assert_false(FanControlsMenu.should_show_card(0))
	assert_true(FanControlsMenu.should_show_card(1))
	assert_false(FanControlsMenu.should_show_selector(1))
	assert_true(FanControlsMenu.should_show_selector(2))


func test_modes_include_preset_as_editable_curve() -> void:
	assert_eq(FanControlsMenu.mode_to_index("automatic"), 0)
	assert_eq(FanControlsMenu.mode_to_index("manual"), 1)
	assert_eq(FanControlsMenu.mode_to_index("curve"), 2)
	assert_eq(FanControlsMenu.mode_to_index("preset"), 2)


func test_first_custom_curve_uses_device_limits_without_a_preset() -> void:
	var curve := FanControlsMenu.initial_curve(45.0, 95.0, 0)
	assert_eq(curve.temperatures, PackedFloat64Array([45.0, 95.0]))
	assert_eq(curve.percents, PackedInt32Array([0, 100]))


func test_fault_message_reports_verified_automatic_fallback() -> void:
	var message := FanControlsMenu.describe_state({
		"compatible": true,
		"fault": "temperature sensor disappeared",
		"automatic_verified": true,
		"suspended": false,
		"mode": "automatic",
	})
	assert_true(message.begins_with("Automatic fallback:"))


func test_limit_summary_includes_zero_duty_hysteresis_and_thermal_handoff() -> void:
	var summary := FanControlsMenu.describe_limits(0, 10, 42.0, 45.0, 95.0, 98.0)
	assert_true(summary.contains("Duty 0-100%"))
	assert_true(summary.contains("Running floor 10%"))
	assert_true(summary.contains("Stop <= 42 C / restart > 45 C"))
	assert_true(summary.contains("Full fan 95 C"))
	assert_true(summary.contains("Firmware handoff 98 C"))


func test_future_api_is_rejected_clearly() -> void:
	assert_true(FanControlsMenu.supports_api_version(1))
	assert_false(FanControlsMenu.supports_api_version(0))
	assert_false(FanControlsMenu.supports_api_version(2))
	var message := FanControlsMenu.describe_state({"compatible": false})
	assert_true(message.contains("Update PowerStation"))


func test_menu_has_controller_focus_group() -> void:
	var menu := MENU_SCENE.instantiate()
	add_child_autoqfree(menu)
	var focus_group := menu.get_node("FocusGroup") as FocusGroup
	assert_not_null(focus_group)
	assert_eq(focus_group.current_focus.name, "ModeDropdown")

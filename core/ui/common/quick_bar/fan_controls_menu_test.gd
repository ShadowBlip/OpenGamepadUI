extends GutTest
const MENU := preload("res://core/ui/common/quick_bar/fan_controls_menu.tscn")
const Fixtures := preload("res://core/systems/performance/fan_profile_model_test.gd")

func test_menu_shows_available_modes_and_does_not_display_invalid_duty() -> void:
	var backend := Fixtures.Backend.new()
	var menu := MENU.instantiate()
	menu.connect_backend = false
	menu.model.start(backend)
	add_child_autofree(menu)
	assert_eq(menu.mode_dropdown.option_button.item_count, 3)
	assert_string_contains(menu.telemetry_label.text, "percentage unavailable")
	assert_string_contains(menu.telemetry_label.text, "CPU: 50.0 C")
	assert_false(menu.telemetry_label.text.contains("RPM"))
	assert_eq(backend.calls.size(), 0)

func test_automatic_button_remains_available_without_sensor_telemetry() -> void:
	var backend := Fixtures.Backend.new()
	backend.state.sensors[0].telemetry_valid = false
	var menu := MENU.instantiate()
	menu.connect_backend = false
	menu.model.start(backend)
	add_child_autofree(menu)
	assert_false(menu.automatic_button.disabled)
	menu.automatic_button.pressed.emit()
	assert_eq(backend.calls.size(), 1)
	assert_eq(backend.calls[0].profile.fans[0].mode, "automatic")
	assert_eq(menu.focus_group.current_focus.name, "AutomaticButton")

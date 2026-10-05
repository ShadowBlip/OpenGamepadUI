extends GutTest

const Model := preload("res://core/systems/input/lighting_model.gd")
const PanelScene := preload("res://core/ui/common/quick_bar/lighting_panel.tscn")

class FakeSource extends RefCounted:
	signal lighting_changed
	signal apply_finished(request: int, success: bool, error: String)
	var calls: Array = []
	var state: Dictionary = {"available": true, "api_version": 1, "persistent_id": "test-rings",
		"effects": ["off", "solid", "breathing", "cycle"], "cycle_min_ms": 2000, "cycle_max_ms": 30000,
		"config": {"effect": "off", "color": [255, 255, 255], "brightness": 30, "cycle_period_ms": 8000},
		"revision": "0", "status": "applied", "error": ""}
	func get_snapshot() -> Dictionary:
		return state.duplicate(true)
	func apply_config(effect: String, color: PackedByteArray, brightness: int, period: int) -> int:
		calls.append({"effect": effect, "color": Array(color), "brightness": brightness, "cycle_period_ms": period})
		return calls.size()
	func complete(success: bool = true, error: String = "") -> void:
		if success:
			state.config = calls.back().duplicate(true)
			state.revision = str(calls.size())
		apply_finished.emit(calls.size(), success, error)

var model: LightingModel
var source: FakeSource

func before_each() -> void:
	model = Model.new()
	source = FakeSource.new()
	model.set_sources([source])

func after_each() -> void:
	model.set_sources([])
	model = null
	source = null

func test_external_state_preserves_dirty_draft() -> void:
	source.state.config.effect = "solid"
	source.lighting_changed.emit()
	await wait_frames(2)
	assert_eq(model.current().draft.effect, "solid")
	model.edit("brightness", 44)
	source.state.config.brightness = 90
	source.lighting_changed.emit()
	await wait_frames(2)
	assert_eq(model.current().snapshot.config.brightness, 90)
	assert_eq(model.current().draft.brightness, 44)

func test_apply_keeps_new_edits_and_uses_latest_saved_state() -> void:
	model.edit("effect", "solid")
	model.apply()
	model.apply()
	assert_eq(source.calls.size(), 1, "Only one request may be in flight")
	model.edit("brightness", 63)
	source.complete()
	await wait_frames(2)
	assert_true(model.current().dirty)
	assert_eq(model.current().draft.brightness, 63)
	model.apply()
	source.complete()
	await wait_frames(2)
	assert_false(model.current().dirty)
	assert_eq(model.current().draft.brightness, 63)

func test_write_error_survives_notifications_and_can_retry() -> void:
	model.edit("effect", "cycle")
	model.apply()
	source.complete(false, "Not authorized")
	await wait_frames(2)
	source.lighting_changed.emit()
	await wait_frames(2)
	assert_eq(model.status_text(), "Not authorized")
	assert_true(model.current().dirty)
	model.apply()
	source.complete()
	await wait_frames(2)
	assert_eq(model.current().error, "")
	assert_false(model.current().busy)

func test_disconnect_restart_preserves_draft_and_ignores_stale_result() -> void:
	model.edit("effect", "breathing")
	model.apply()
	model.set_sources([])
	assert_false(model.current().busy)
	assert_false(model.current().snapshot.available)
	var replacement := FakeSource.new()
	model.set_sources([replacement])
	source.complete()
	await wait_frames(2)
	assert_eq(model.current().draft.effect, "breathing")
	assert_true(model.current().dirty)
	assert_true(model.current().snapshot.available)
	model.apply()
	replacement.complete()
	await wait_frames(2)
	assert_false(model.current().dirty)

func test_turn_off_retains_remembered_color_and_brightness() -> void:
	model.edit("color", [12, 23, 34])
	model.edit("brightness", 47)
	model.apply(true)
	assert_eq(source.calls[0], {"effect": "off", "color": [12, 23, 34], "brightness": 47, "cycle_period_ms": 8000})
	source.complete()
	await wait_frames(2)
	assert_eq(model.current().draft.brightness, 47)

func test_hardware_failure_is_distinct_from_successful_save() -> void:
	model.apply()
	source.state.status = "failed"
	source.state.error = "Device write failed"
	source.complete()
	await wait_frames(2)
	assert_false(model.current().dirty)
	assert_string_contains(model.status_text(), "saved")
	assert_string_contains(model.status_text(), "Device write failed")

func test_multiple_devices_have_separate_drafts() -> void:
	var other := FakeSource.new()
	other.state.persistent_id = "other-rings"
	model.set_sources([source, other])
	model.edit("brightness", 11)
	model.select_device("other-rings")
	model.edit("brightness", 22)
	model.select_device("test-rings")
	assert_eq(model.current().draft.brightness, 11)
	model.select_device("other-rings")
	assert_eq(model.current().draft.brightness, 22)

func test_duplicate_identity_is_unavailable() -> void:
	var other := FakeSource.new()
	model.set_sources([source, other])
	source.lighting_changed.emit()
	await wait_frames(2)
	assert_false(model.current().snapshot.available)
	model.apply()
	assert_eq(source.calls.size(), 0)
	assert_eq(other.calls.size(), 0)

func _panel() -> Control:
	var panel := PanelScene.instantiate()
	panel.model = model
	panel.connect_backend = false
	panel.size = Vector2(420, 1000)
	add_child_autofree(panel)
	return panel

func test_panel_retains_draft_request_and_error_across_remount() -> void:
	var first := _panel()
	await wait_frames(2)
	model.edit("effect", "solid")
	model.edit("brightness", 69)
	model.apply()
	first.queue_free()
	await wait_frames(2)
	var second := _panel()
	await wait_frames(2)
	assert_eq(second.brightness.value, 69.0)
	assert_true(second.apply_button.disabled)
	source.complete(false, "Authorization denied")
	await wait_frames(2)
	assert_false(second.apply_button.disabled)
	assert_eq(second.status.text, "Authorization denied")
	assert_eq(source.calls.size(), 1, "Closing a panel must never issue Off")

func test_controls_capabilities_and_focus_follow_effect() -> void:
	var panel := _panel()
	await wait_frames(2)
	model.edit("effect", "cycle")
	await wait_frames(2)
	assert_true(panel.cycle.visible)
	assert_false(panel.red.visible)
	assert_false(panel.breathing_note.visible)
	var controls: Array[Control] = panel._focus_controls()
	assert_eq(controls.size(), 5)
	panel.effect.option_button.grab_focus()
	assert_eq(panel.effect.option_button.find_valid_focus_neighbor(SIDE_BOTTOM), panel.brightness.slider)
	panel.brightness.slider.grab_focus()
	assert_eq(panel.brightness.slider.find_valid_focus_neighbor(SIDE_BOTTOM), panel.cycle.slider)
	model.edit("effect", "breathing")
	await wait_frames(2)
	assert_false(panel.cycle.visible)
	assert_true(panel.red.visible)
	assert_true(panel.breathing_note.visible)
	assert_eq(panel._focus_controls().size(), 7)
	source.state.effects = ["off", "solid"]
	source.lighting_changed.emit()
	await wait_frames(2)
	assert_true(panel.apply_button.disabled)
	assert_false(panel.red.visible)
	assert_eq(panel.effect.option_button.item_count, 2)
	model.edit("effect", "solid")
	await wait_frames(2)
	assert_false(panel.apply_button.disabled)

func test_missing_backend_shows_unavailable_and_no_controls() -> void:
	model.set_sources([])
	var panel := _panel()
	await wait_frames(2)
	assert_false(panel.effect.visible)
	assert_false(panel.apply_button.visible)
	assert_string_contains(panel.status.text, "disconnected")

func test_stock_quick_settings_scroll_and_controller_focus() -> void:
	var scene := load("res://core/ui/common/quick_bar/quick_settings_menu.tscn") as PackedScene
	var menu := scene.instantiate() as Control
	# Isolate layout/navigation from the existing audio/backlight integrations.
	menu.set_script(null)
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	menu.size = Vector2(480, 450)
	var panel: Control = menu.get_node("Scroll/QuickVBoxContainer/JoystickLighting")
	panel.model = model
	panel.connect_backend = false
	add_child_autofree(menu)
	model.edit("effect", "solid")
	await wait_frames(4)
	var scroll: ScrollContainer = menu.get_node("Scroll")
	var volume: Control = menu.get_node("Scroll/QuickVBoxContainer/VolumeSlider")
	var saturation: Control = menu.get_node("Scroll/QuickVBoxContainer/SaturationSlider")
	assert_eq(panel.effect.option_button.get_node(panel.effect.option_button.focus_neighbor_top), saturation)
	assert_eq(panel.off_button.get_node(panel.off_button.focus_neighbor_bottom), volume)
	panel.off_button.grab_focus()
	await wait_frames(3)
	assert_gt(scroll.scroll_vertical, 0, "Controller focus must scroll the lower controls into view")
	var bottom: float = panel.off_button.get_global_rect().end.y
	assert_true(bottom <= scroll.get_global_rect().end.y + 1.0)
	var event := InputEventAction.new()
	event.action = "ui_down"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_frames(2)
	assert_eq(get_viewport().gui_get_focus_owner(), volume.slider)

func test_native_cycle_hides_speed_preserves_period_and_keeps_gamepad_focus() -> void:
	source.state.cycle_min_ms = 0
	source.state.cycle_max_ms = 0
	source.state.config.effect = "cycle"
	source.state.config.cycle_period_ms = 17000
	source.lighting_changed.emit()
	await wait_frames(2)
	var panel := _panel()
	await wait_frames(2)
	assert_false(panel.cycle.visible)
	assert_true(panel.breathing_note.visible)
	assert_eq(panel.breathing_note.text, "Colour cycle speed is fixed by the device.")
	assert_eq(panel._focus_controls().size(), 4)
	panel.brightness.slider.grab_focus()
	assert_eq(panel.brightness.slider.find_valid_focus_neighbor(SIDE_BOTTOM), panel.apply_button)
	model.edit("brightness", 60)
	model.apply()
	assert_eq(source.calls.size(), 1)
	assert_eq(source.calls[0].cycle_period_ms, 17000)
	source.complete()
	await wait_frames(2)
	source.state.cycle_min_ms = 2000
	source.state.cycle_max_ms = 30000
	source.lighting_changed.emit()
	await wait_frames(2)
	assert_true(panel.cycle.visible)
	assert_eq(panel.cycle.value, 17.0)
	assert_false(panel.breathing_note.visible)

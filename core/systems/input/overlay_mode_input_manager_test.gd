extends GutTest

const GUIDE_ACTIONS := ["ogui_osk_ov", "ogui_qam_ov", "ogui_vc_ov", "ogui_sc_ov", "ogui_qb_ov"]

var manager: RecordingManager


class RecordingManager extends OverlayInputManager:
	var released_actions: Array[String] = []

	func _ready() -> void:
		set_process_input(false)

	func action_release(_dbus_path: String, action: String, _strength: float = 1.0) -> void:
		Input.action_release(action)
		released_actions.append(action)


func before_each() -> void:
	_clear_actions()
	manager = RecordingManager.new()
	add_child_autofree(manager)


func after_each() -> void:
	_clear_actions()


func _clear_actions() -> void:
	for action: String in GUIDE_ACTIONS:
		Input.action_release(action)
	Input.action_release("ogui_guide_ov")
	Input.action_release("ogui_guide_action")


func _release_event(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = false
	event.set_meta("dbus_path", "/test/device")
	return event


func test_guide_action_release_clears_all_active_actions() -> void:
	for action: String in GUIDE_ACTIONS:
		Input.action_press(action)

	manager._input(_release_event("ogui_guide_action"))

	assert_eq(manager.released_actions, GUIDE_ACTIONS)
	for action: String in GUIDE_ACTIONS:
		assert_false(Input.is_action_pressed(action), action + " should be released")


func test_guide_action_release_ignores_inactive_actions() -> void:
	manager._input(_release_event("ogui_guide_action"))

	assert_eq(manager.released_actions.size(), 0)


func test_rb_release_clears_screenshot_while_guide_is_held() -> void:
	Input.action_press("ogui_guide_ov")
	Input.action_press("ogui_sc_ov")

	manager._input(_release_event("ogui_rb_ov"))

	assert_eq(manager.released_actions, ["ogui_sc_ov"])
	assert_false(Input.is_action_pressed("ogui_sc_ov"))

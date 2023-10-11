extends GutTest

# TODO: Figure out how to test in headless mode
var headless := RenderingServer.get_video_adapter_api_version() == ""
var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var state := load("res://assets/state/states/main_menu.tres") as State
var scene := load("res://core/ui/card_ui/main-menu/main_menu.tscn") as PackedScene
var node: Node


# Add the menu scene and ensure the starting state before each test
func before_each() -> void:
	if headless:
		return
	var instance := scene.instantiate()
	node = instance
	add_child(node)
	await wait_frames(1, "wait for menu")
	state_machine.push_state(state)


# Clear the state machine after each test
func after_each() -> void:
	if headless:
		return
	while state_machine.stack_length() > 0:
		state_machine.pop_state()


# Stop all threads to prevent crashing
func after_all() -> void:
	var thread_pool := load("res://core/systems/threading/thread_pool.tres") as ThreadPool
	var input_thread := load("res://core/systems/threading/input_thread.tres") as SharedThread
	thread_pool.stop()
	input_thread.stop()


# Test that the main menu is focused
func test_focus() -> void:
	if headless:
		pass_test("Running headless, skipping")
		return
	var focus_group := node.get_node("%FocusGroup") as FocusGroup
	assert_true(focus_group.is_focused(), "focus group is focused")


# Used to test that all buttons in the menu go to the correct state
var button_states_params := [
	["res://assets/state/states/library.tres", "%ButtonContainer/LibraryButton"],
	["res://assets/state/states/home.tres", "%ButtonContainer/HomeButton"],
	#["res://assets/state/states/store.tres", "%ButtonContainer/StoreButton"],
	["res://assets/state/states/settings.tres", "%ButtonContainer/SettingsButton"],
	["res://assets/state/states/power_menu.tres", "%ButtonContainer/PowerButton"],
]

# Test that pressing all the buttons will go to the correct state. This 
# will test all of the buttons listed in 'button_states_params'.
func test_button_states(params=use_parameters(button_states_params)) -> void:
	if headless:
		pass_test("Running in headless mode, skipping")
		return
	var state_path := params[0] as String
	var button_path := params[1] as String
	var state := load(state_path) as State
	var button := node.get_node(button_path) as CardButton
	
	await _test_button_state(state, button)
	assert_same(state_machine.current_state(), state, "should enter the correct state")


func _test_button_state(state: State, button: CardButton) -> void:
	# Wait for the menu to fully open
	var effect := node.get_node("StateWatcher/SlideEffect") as Effect
	await effect.effect_finished

	# Grab focus on the button
	button.grab_focus()
	await wait_frames(1)

	# Emulate pressing the button
	var event := InputFactory.action_up("ui_accept") as InputEvent
	Input.parse_input_event(event)
	await wait_frames(1)

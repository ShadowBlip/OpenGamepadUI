extends GutTest

var state_watcher: StateWatcher
var state_machine: StateMachine
var state: State
var node: Node


# Add the menu scene and ensure the starting state before each test
func before_each() -> void:
	# Create a state machine and state
	state_machine = StateMachine.new()
	state = State.new()

	# Create a state watcher
	state_watcher = StateWatcher.new()
	state_watcher.state = state
	watch_signals(state_watcher)

	# Add the state watcher
	node = add_child_autoqfree(state_watcher)
	await wait_frames(1, "wait for ready")


# Test that the state watcher emits when state is entered
func test_state_entered() -> void:
	state_machine.push_state(state)
	assert_signal_emitted(state_watcher, "state_entered")


# Test that the state watcher emits when state is exited
func test_state_exited() -> void:
	state_machine.push_state(state)
	state_machine.pop_state()
	assert_signal_emitted(state_watcher, "state_exited")


# Test that the state watcher emits when state is exited
func test_state_exited_from_push() -> void:
	var state2 := State.new()
	state_machine.push_state(state)
	state_machine.push_state(state2)
	assert_signal_emitted(state_watcher, "state_exited")
	assert_signal_not_emitted(state_watcher, "state_removed")

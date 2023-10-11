extends GutTest


var state_machine: StateMachine
var state: State
var state_updater: StateUpdater
var node: Button


func before_each() -> void:
	# Create a state machine and state
	state_machine = StateMachine.new()
	state = State.new()

	# Create and configure the state updater
	state_updater = StateUpdater.new()
	state_updater.state_machine = state_machine
	state_updater.state = state
	state_updater.on_signal = "focus_entered"

	# Create a node instance to attach the state updater to
	var instance := Button.new()
	instance.add_child(state_updater)
	node = add_child_autoqfree(instance)
	await wait_frames(1, "wait for node")


func test_push_state() -> void:
	state_updater.action = state_updater.ACTION.PUSH
	node.grab_focus()
	assert_same(state_machine.current_state(), state, "should have pushed the state")


func test_pop_state() -> void:
	state_updater.action = state_updater.ACTION.POP
	state_machine.set_state([state])
	node.grab_focus()
	assert_eq(state_machine.stack_length(), 0, "should have popped the state stack")


func test_replace_state() -> void:
	state_updater.action = state_updater.ACTION.REPLACE
	state_machine.set_state([State.new(), State.new()])
	node.grab_focus()
	assert_eq(state_machine.stack_length(), 2, "should have only replaced the state")
	assert_same(state_machine.current_state(), state, "should have replaced it with the state")


func test_set_state() -> void:
	state_updater.action = state_updater.ACTION.SET
	state_machine.set_state([State.new(), State.new()])
	node.grab_focus()
	assert_eq(state_machine.stack_length(), 1, "should have removed all states but one")
	assert_same(state_machine.current_state(), state, "should have replaced it with the state")

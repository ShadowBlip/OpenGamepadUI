extends GutTest

var state_machine: StateMachine


func before_each() -> void:
	state_machine = StateMachine.new()
	watch_signals(state_machine)


func test_push_state() -> void:
	var state := State.new()
	state_machine.push_state(state)
	assert_eq(state_machine.stack_length(), 1, "should have one state in the stack")
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [null, state])


func test_pop_state() -> void:
	var state := State.new()
	state_machine.set_state([state])
	var popped := state_machine.pop_state()
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [state, null])
	assert_eq(state_machine.stack_length(), 0, "should have no state in the stack")
	assert_same(state, popped, "popped state is original state")

extends GutTest

var state_machine: StateMachine


func before_each() -> void:
	state_machine = StateMachine.new()
	state_machine.minimum_states = 0
	watch_signals(state_machine)


func test_set_state() -> void:
	var state1 := State.new()
	state1.name = "State1"
	watch_signals(state1)
	var state2 := State.new()
	state2.name = "State2"
	watch_signals(state2)
	var state3 := State.new()
	state3.name = "State3"
	watch_signals(state3)
	state_machine.set_state([state1, state2, state3])
	assert_eq(state_machine.stack_length(), 3, "should have three states in the stack")
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [null, state3])
	assert_signal_emitted(state1, "state_added", "should have emitted state_added signal")
	assert_signal_emitted(state2, "state_added", "should have emitted state_added signal")
	assert_signal_emitted(state3, "state_added", "should have emitted state_added signal")
	assert_signal_emitted_with_parameters(state3, "state_entered", [null])
	assert_signal_not_emitted(state2, "state_entered", "state2 should not have been entered")
	assert_signal_not_emitted(state1, "state_entered", "state1 should not have been entered")

	state_machine.set_state([state2])
	assert_eq(state_machine.stack_length(), 1, "should have one state in the stack")
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [state3, state2])
	assert_signal_emitted(state1, "state_removed", "should have emitted state_removed signal")
	assert_signal_emitted(state3, "state_removed", "should have emitted state_removed signal")
	assert_signal_emitted_with_parameters(state2, "state_entered", [state3])
	assert_signal_emitted_with_parameters(state3, "state_exited", [state2])


func test_push_state() -> void:
	var state1 := State.new()
	state1.name = "State1"
	watch_signals(state1)
	state_machine.push_state(state1)
	assert_eq(state_machine.stack_length(), 1, "should have one state in the stack")
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [null, state1])
	assert_signal_emitted(state1, "state_added", "should have emitted state_added signal")
	assert_signal_emitted_with_parameters(state1, "state_entered", [null])
	
	var state2 := State.new()
	state2.name = "State2"
	watch_signals(state2)
	state_machine.push_state(state2)
	assert_eq(state_machine.stack_length(), 2, "should have two states in the stack")
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [state1, state2])
	assert_signal_emitted_with_parameters(state1, "state_exited", [state2])
	assert_signal_emitted(state2, "state_added", "should have emitted state_added signal")
	assert_signal_emitted_with_parameters(state2, "state_entered", [state1])


func test_push_state_front() -> void:
	var state1 := State.new()
	state1.name = "State1"
	watch_signals(state1)
	var state2 := State.new()
	state2.name = "State2"
	watch_signals(state2)
	state_machine.push_state_front(state1)
	state_machine.push_state_front(state2)
	assert_eq(state_machine.stack_length(), 2, "should have two states in the stack")
	assert_eq(state_machine.current_state(), state1, "state1 should be the current state")
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [null, state1])
	assert_signal_emitted(state1, "state_added")
	assert_signal_emitted(state2, "state_added")
	assert_signal_not_emitted(state2, "state_entered", "state2 should not have been entered")
	assert_signal_emitted_with_parameters(state1, "state_entered", [null])


func test_pop_state() -> void:
	var state := State.new()
	state.name = "State1"
	state_machine.set_state([state])
	watch_signals(state)
	var popped := state_machine.pop_state()
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [state, null])
	assert_signal_emitted_with_parameters(state, "state_exited", [null])
	assert_signal_emitted(state, "state_removed", "should have emitted state_removed signal")
	assert_eq(state_machine.stack_length(), 0, "should have no state in the stack")
	assert_same(state, popped, "popped state is original state")

	popped = state_machine.pop_state()
	assert_eq(state_machine.stack_length(), 0, "should have no state in the stack")
	assert_null(popped)

	state_machine.minimum_states = 1
	state_machine.push_state(state)
	state_machine.pop_state()
	assert_eq(state_machine.stack_length(), 1, "should have not have popped state")


func test_replace_state() -> void:
	var state1 := State.new()
	state1.name = "State1"
	watch_signals(state1)
	var state2 := State.new()
	state2.name = "State2"
	watch_signals(state2)
	state_machine.replace_state(state1)
	assert_eq(state_machine.stack_length(), 1, "should have one state in the stack")
	assert_eq(state_machine.current_state(), state1, "state1 should be the current state")
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [null, state1])
	assert_signal_emitted(state1, "state_added")
	assert_signal_emitted_with_parameters(state1, "state_entered", [null])

	state_machine.replace_state(state2)
	assert_eq(state_machine.stack_length(), 1, "should have one state in the stack")
	assert_eq(state_machine.current_state(), state2, "state2 should be the current state")
	assert_signal_emitted_with_parameters(state_machine, "state_changed", [state1, state2])
	assert_signal_emitted(state2, "state_added")
	assert_signal_emitted_with_parameters(state1, "state_exited", [state2])
	assert_signal_emitted_with_parameters(state2, "state_entered", [state1])

	var state3 := State.new()
	state3.name = "State3"
	state_machine.replace_state(state3)
	watch_signals(state3)
	state_machine.replace_state(state3)
	assert_signal_not_emitted(state3, "state_entered", "should not have re-entered state")
	assert_signal_not_emitted(state3, "state_exited", "should not have exited state")
	assert_signal_not_emitted(state3, "state_removed", "should not have removed state")
	assert_signal_not_emitted(state3, "state_added", "should not have added state")


func test_remove_state() -> void:
	var state1 := State.new()
	state1.name = "State1"
	watch_signals(state1)
	var state2 := State.new()
	state2.name = "State2"
	watch_signals(state2)
	var state3 := State.new()
	state3.name = "State3"
	watch_signals(state3)
	state_machine.set_state([state1, state2, state3])
	assert_eq(state_machine.stack_length(), 3, "should have three states in the stack")

	state_machine.remove_state(state3)
	assert_eq(state_machine.stack_length(), 2, "should have two states in the stack")
	assert_eq(state_machine.current_state(), state2, "state2 should be the current state")
	assert_signal_emitted_with_parameters(state2, "state_entered", [state3])
	assert_signal_emitted_with_parameters(state3, "state_exited", [state2])
	assert_signal_emitted(state3, "state_removed")
	assert_signal_not_emitted(state1, "state_entered")
	assert_signal_not_emitted(state1, "state_exited")

	state_machine.remove_state(state1)
	assert_eq(state_machine.stack_length(), 1, "should have one state in the stack")
	assert_eq(state_machine.current_state(), state2, "state2 should be the current state")
	assert_signal_emitted(state1, "state_removed")
	assert_signal_not_emitted(state1, "state_entered")
	assert_signal_not_emitted(state1, "state_exited")


func test_clear_state() -> void:
	var state1 := State.new()
	state1.name = "State1"
	var state2 := State.new()
	state2.name = "State2"
	var state3 := State.new()
	state3.name = "State3"

	state_machine.set_state([state1, state2, state3])
	watch_signals(state1)
	watch_signals(state2)
	watch_signals(state3)
	state_machine.clear_states()
	assert_eq(state_machine.stack_length(), 0, "should have no states in the stack")
	assert_signal_emitted(state1, "state_removed")
	assert_signal_emitted(state2, "state_removed")
	assert_signal_emitted(state3, "state_removed")
	assert_signal_emitted_with_parameters(state3, "state_exited", [null])

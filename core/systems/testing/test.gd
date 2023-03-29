extends Node
class_name Test

## Emitted after tests havev been completed
signal test_finished
## Emitted when a test assertion fails
signal assert_failed(assertion: Assertion)

## The name of the test
@export var test_name: String = "Test"
## Whether or not to finish the test after _ready() returns. If this is false,
## you must call finish() to end the test.
@export var finish_after_ready: bool = true
## Whether or not to print assertions during the test run
@export var print_assertions: bool = false
var logger := Log.get_logger(test_name)

## Test assertion
class Assertion:
	var test: String
	var stack: Array
	var caller: Dictionary
	var reason: String


func _init() -> void:
	var on_ready := func():
		if not finish_after_ready:
			return
		finish()
	ready.connect(on_ready)
	assert_failed.connect(print_assertion)


func assert_true(expr: bool) -> void:
	if not expr:
		var assertion := Assertion.new()
		assertion.caller = _get_caller()
		assertion.stack = get_stack()
		assertion.test = test_name
		assertion.reason = "Expression does not evaluate to true"
		assert_failed.emit(assertion)


func assert_equals(v1: Variant, v2: Variant) -> void:
	if v1 != v2:
		var assertion := Assertion.new()
		assertion.caller = _get_caller()
		assertion.stack = get_stack()
		assertion.test = test_name
		assertion.reason = "{0} != {1}".format([v1, v2])
		assert_failed.emit(assertion)


func _get_caller() -> Dictionary:
	var stack := get_stack()
	if len(stack) == 0:
		return {"source": "", "line": 0}
	return stack[2]


func print_assertion(assertion: Test.Assertion) -> void:
	if not print_assertions:
		return
	var msg := "Assert failed: {0}:{1}():{2}: {3}".format([
		assertion.caller["source"],
		assertion.caller["function"],
		assertion.caller["line"],
		assertion.reason,
	])
	logger.error(msg)


func _is_running_standalone() -> bool:
	if get_parent().name == "RunTests":
		return false
	return true


func finish() -> void:
	if _is_running_standalone():
		queue_free()
	get_tree().quit()


func _exit_tree() -> void:
	test_finished.emit()

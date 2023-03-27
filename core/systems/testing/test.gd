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
var logger := Log.get_logger(test_name)

## Test assertion
class Assertion:
	var test: String
	var stack: Array
	var caller: Dictionary
	var reason: String


func _init() -> void:
	if not finish_after_ready:
		return
	var on_ready := func():
		finish()
	ready.connect(on_ready)


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


func finish() -> void:
	queue_free()


func _exit_tree() -> void:
	test_finished.emit()

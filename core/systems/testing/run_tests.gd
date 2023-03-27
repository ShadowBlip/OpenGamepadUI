extends Node

var tests: PackedStringArray
var running_tests := []
var completed_tests := []
var failed_tests := []
var logger := Log.get_logger("Testing")


func _ready() -> void:
	tests = _find_tests("res://")
	logger.info("Found tests: " + str(tests))
	for test_file in tests:
		run_test(test_file)
	
	if running_tests.size() == 0:
		finish()


func _on_assert_failed(assertion: Test.Assertion, test_name: String) -> void:
	var msg := "Assert failed: {0}:{1}():{2}: {3}".format([
		assertion.caller["source"],
		assertion.caller["function"],
		assertion.caller["line"],
		assertion.reason,
	])
	logger.error(msg)
	failed_tests.append(assertion)


func _on_test_finished(test_name: String) -> void:
	logger.info("Finished running test: " + test_name)
	completed_tests.append(test_name)
	if tests.size() == completed_tests.size():
		finish()


func run_test(test_file: String) -> void:
	var scene := load(test_file) as PackedScene
	var test := scene.instantiate()
	if not test is Test:
		logger.warn("Scene does not inherit from Test: " + test_file)
		return
	
	running_tests.append(test.test_name)
	test.test_finished.connect(_on_test_finished.bind(test.test_name))
	test.assert_failed.connect(_on_assert_failed.bind(test.test_name))
	logger.info("Running test: " + test.name)
	add_child(test)


func finish() -> void:
	print("")
	logger.info("Testing completed")
	
	var code := OK
	if failed_tests.size() != 0:
		code = FAILED
	if code != OK:
		logger.error("Tests have failed")
		print("")
		for a in failed_tests:
			var asrt := a as Test.Assertion
			logger.error("Test '{0}' failed at {1}:{2}".format([asrt.test, asrt.caller["source"], asrt.caller["line"]]))
		
	get_tree().quit(code)


func _find_tests(folder: String) -> PackedStringArray:
	var root := DirAccess.open(folder)
	var tests := PackedStringArray()
	
	var files := root.get_files()
	for file in files:
		if file.ends_with("_test.tscn"):
			var path := "/".join([folder, file])
			tests.append(path)
	
	var dirs := root.get_directories()
	for subdir in dirs:
		var path := "/".join([folder, subdir])
		tests.append_array(_find_tests(path))
	
	return tests

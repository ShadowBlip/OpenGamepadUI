extends GutTest


func test_pipe() -> void:
	var pipe_manager := PipeManager.new()
	add_child_autoqfree(pipe_manager)
	watch_signals(pipe_manager)
	gut.p("Got manager: " + str(pipe_manager))

	var run_path := pipe_manager.get_run_path()
	if not DirAccess.dir_exists_absolute(run_path):
		pass_test("Unable to create pipe directory for test. Skipping.")
		return

	var on_line_written := func(line: String):
		gut.p("Got message: " + line)
		assert_eq(line, "test")
	pipe_manager.line_written.connect(on_line_written)
	
	OS.execute("sh", ["-c", "echo -n test > " + pipe_manager.get_pipe_path()])
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_signal_emitted(pipe_manager, "line_written", "should emit line")

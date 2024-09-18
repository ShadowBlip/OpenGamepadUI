extends GutTest


func test_subreaper_create_process() -> void:
	var pid := SubReaper.create_process("sleep", ["1"])
	gut.p("Got reaper PID: " + str(pid))

	assert_true(OS.is_process_running(pid), "reaper process should be running")
	await wait_seconds(2)
	assert_false(OS.is_process_running(pid), "reaper process should have exited")

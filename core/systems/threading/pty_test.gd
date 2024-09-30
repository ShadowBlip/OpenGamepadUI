extends GutTest


func test_pty() -> void:
	var pty := Pty.new()
	add_child_autoqfree(pty)

	# Listen for output from the command
	var on_line_written := func(line: String):
		gut.p("Line: " + line)
		if line.contains("Type something:"):
			pty.write_line("Hello World")
	pty.line_written.connect(on_line_written)

	# Execute the command in the PTY
	var result := pty.exec("bash", PackedStringArray(["-c", "read -p 'Type something: ' foo; echo 'You typed:' $foo"]))
	assert_eq(result, OK)

	# Wait for the command to exit
	var exit_code = await pty.finished

	gut.p("Command finished with exit code: " + str(exit_code))

	await wait_seconds(5, "Waiting")

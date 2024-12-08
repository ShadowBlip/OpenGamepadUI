extends GutTest


func test_command():
	# Ensure the [ResourceProcessor] node is added to the scene tree
	var resource_processor := ResourceProcessor.new()
	resource_processor.registry = load("res://core/systems/resource/resource_registry.tres") as ResourceRegistry
	add_child_autoqfree(resource_processor)

	var command := Command.create("ls", ["/", "/idontexistforrealz"])
	gut.p("Executing command: " + command.command + " " + str(command.args))
	if command.execute() != OK:
		gut.p("  Failed to start executing command")
	var code := await command.finished as int
	gut.p("  Command exited with code: " + str(code))
	gut.p(command.stdout)
	gut.p(command.stderr)
	assert_false(command.stdout.is_empty(), "should return output")
	assert_eq(command.stderr, "ls: cannot access '/idontexistforrealz': No such file or directory\n", "should produce error output")

	command = Command.create("echo", ["-n", "one", "two", "three"])
	gut.p("Executing command: " + command.command + " " + str(command.args))
	if command.execute() != OK:
		gut.p("  Failed to start executing command")
	code = await command.finished as int
	gut.p("  Command exited with code: " + str(code))
	gut.p(command.stdout)
	assert_eq(code, OK, "should return zero")
	assert_eq(command.stdout, "one two three", "should have correct output")

	command = Command.create("Id0NtEx1st", [])
	gut.p("Executing command: " + command.command + " " + str(command.args))
	if command.execute() != OK:
		gut.p("  Failed to start executing command")
	code = await command.finished as int
	assert_ne(code, OK, "should fail to run")


func test_command_cancel():
	# Ensure the [ResourceProcessor] node is added to the scene tree
	var resource_processor := ResourceProcessor.new()
	resource_processor.registry = load("res://core/systems/resource/resource_registry.tres") as ResourceRegistry
	add_child_autoqfree(resource_processor)

	var command := Command.create("sleep", ["5"])
	command.timeout = 1.0
	gut.p("Executing command: " + command.command + " " + str(command.args))
	if command.execute() != OK:
		gut.p("  Failed to start executing command")
	var code := await command.finished as int
	gut.p("  Command exited with code: " + str(code))
	assert_eq(code, command.EXIT_CODE_CANCEL, "should exit with code 130, indicating cancellation")


func test_command_sync():
	var command := Command.create("sleep", ["1"])
	gut.p("Executing command: " + command.command + " " + str(command.args))
	var code := command.execute_blocking()
	gut.p("  Command exited with code: " + str(code))
	assert_eq(code, 0, "should exit ok")

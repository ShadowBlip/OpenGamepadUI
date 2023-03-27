extends Test

enum PROPS {
	NONE = 0,
	FOO = 1,
	BAR = 2,
	BOO = 4,
}


func _ready() -> void:
	# Create flags
	var flags := Bitwise.flags([PROPS.FOO, PROPS.BAR, PROPS.BOO])
	logger.info("Flags: " + str(flags))
	assert_true(flags == 7)

	# Has flag
	assert_true(Bitwise.has_flag(flags, PROPS.FOO))
	assert_true(Bitwise.has_flag(flags, PROPS.BAR))
	assert_true(Bitwise.has_flag(flags, PROPS.BOO))

	# Clear flag
	flags = Bitwise.clear_flag(flags, PROPS.BOO)
	print("Clear: ", flags)
	assert_true(Bitwise.has_flag(flags, PROPS.FOO))
	assert_true(Bitwise.has_flag(flags, PROPS.BAR))
	assert_true(not Bitwise.has_flag(flags, PROPS.BOO))

	# Set flag
	flags = Bitwise.set_flag(flags, PROPS.BOO)
	assert_true(Bitwise.has_flag(flags, PROPS.FOO))
	assert_true(Bitwise.has_flag(flags, PROPS.BAR))
	assert_true(Bitwise.has_flag(flags, PROPS.BOO))

	# Toggle flag
	flags = Bitwise.toggle_flag(flags, PROPS.FOO)
	assert_true(not Bitwise.has_flag(flags, PROPS.FOO))
	flags = Bitwise.toggle_flag(flags, PROPS.FOO)
	assert_true(Bitwise.has_flag(flags, PROPS.FOO))

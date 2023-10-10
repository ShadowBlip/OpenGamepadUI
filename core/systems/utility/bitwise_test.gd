extends GutTest

enum PROPS {
	NONE = 0,
	FOO = 1,
	BAR = 2,
	BOO = 4,
}

var flags := Bitwise.flags([PROPS.FOO, PROPS.BAR, PROPS.BOO])

# Ran before each test
func before_each() -> void:
	flags = Bitwise.flags([PROPS.FOO, PROPS.BAR, PROPS.BOO])


# Test that all flags add up
func test_flags_set() -> void:
	assert_true(flags == 7, "should add up to 7")


# Test has flag
func test_has_flag() -> void:
	assert_true(Bitwise.has_flag(flags, PROPS.FOO), "should have PROPS.FOO flag")
	assert_true(Bitwise.has_flag(flags, PROPS.BAR), "should have PROPS.BAR flag")
	assert_true(Bitwise.has_flag(flags, PROPS.BOO), "should have PROPS.BOO flag")


# Test clearing flags
func test_clear_flag() -> void:
	flags = Bitwise.clear_flag(flags, PROPS.BOO)
	gut.p("Cleared: ", flags)
	assert_true(Bitwise.has_flag(flags, PROPS.FOO), "should have PROPS.FOO flag")
	assert_true(Bitwise.has_flag(flags, PROPS.BAR), "should have PROPS.BAR flag")
	assert_true(not Bitwise.has_flag(flags, PROPS.BOO), "should not have PROPS.BOO flag")


# Test toggling flags
func test_toggle_flag() -> void:
	flags = Bitwise.toggle_flag(flags, PROPS.FOO)
	assert_true(not Bitwise.has_flag(flags, PROPS.FOO), "should not have PROPS.FOO flag")
	flags = Bitwise.toggle_flag(flags, PROPS.FOO)
	assert_true(Bitwise.has_flag(flags, PROPS.FOO), "should have PROPS.FOO flag")

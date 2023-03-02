extends Node

enum PROPS {
	NONE = 0,
	FOO = 1,
	BAR = 2,
	BOO = 4,
}

@onready var timer := Timer.new()


func _ready() -> void:
	# Create flags
	var flags := Bitwise.flags([PROPS.FOO, PROPS.BAR, PROPS.BOO])
	print("Flags: ", flags)
	assert(flags == 7)

	# Has flag
	assert(Bitwise.has_flag(flags, PROPS.FOO))
	assert(Bitwise.has_flag(flags, PROPS.BAR))
	assert(Bitwise.has_flag(flags, PROPS.BOO))

	# Clear flag
	flags = Bitwise.clear_flag(flags, PROPS.BOO)
	print("Clear: ", flags)
	assert(Bitwise.has_flag(flags, PROPS.FOO))
	assert(Bitwise.has_flag(flags, PROPS.BAR))
	assert(not Bitwise.has_flag(flags, PROPS.BOO))

	# Set flag
	flags = Bitwise.set_flag(flags, PROPS.BOO)
	assert(Bitwise.has_flag(flags, PROPS.FOO))
	assert(Bitwise.has_flag(flags, PROPS.BAR))
	assert(Bitwise.has_flag(flags, PROPS.BOO))

	# Toggle flag
	flags = Bitwise.toggle_flag(flags, PROPS.FOO)
	assert(not Bitwise.has_flag(flags, PROPS.FOO))
	flags = Bitwise.toggle_flag(flags, PROPS.FOO)
	assert(Bitwise.has_flag(flags, PROPS.FOO))

	print("All tests passed")
	timer.wait_time = 1
	timer.autostart = true
	timer.timeout.connect(get_tree().quit)
	add_child(timer)

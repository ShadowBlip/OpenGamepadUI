extends GutTest

const EV_ABS := InputDeviceEvent.EV_ABS
const ABS_X := InputDeviceEvent.ABS_X
const ABS_Y := InputDeviceEvent.ABS_Y
const ABS_Z := InputDeviceEvent.ABS_Z
const ABS_RX := InputDeviceEvent.ABS_RX
const ABS_RY := InputDeviceEvent.ABS_RY
const ABS_RZ := InputDeviceEvent.ABS_RZ


# Test parameters for testing normalizing an axis value from -1 - 1.
# The test data should be in the following form:
# 	[axis_min, axis_max, [event_codes], value, normalized_value]
var normalize_axis_params := [
	# Test values that emulate a Playstation controller. These controllers
	# use only positive values for their joystick axes.
	[NormalizeAxisParam.new(   0, 300, [ABS_X, ABS_Y, ABS_RX, ABS_RY], 150,  0.0)],
	[NormalizeAxisParam.new(   0, 300, [ABS_X, ABS_Y, ABS_RX, ABS_RY],   0, -1.0)],
	[NormalizeAxisParam.new(   0, 300, [ABS_X, ABS_Y, ABS_RX, ABS_RY], 300,  1.0)],
	[NormalizeAxisParam.new(   0, 300, [ABS_X, ABS_Y, ABS_RX, ABS_RY],  75, -0.5)],
	[NormalizeAxisParam.new(   0, 300, [ABS_X, ABS_Y, ABS_RX, ABS_RY], 225,  0.5)],

	# Test values with a positive/negative min/max range like XBox controllers.
	[NormalizeAxisParam.new(-100, 100, [ABS_X, ABS_Y, ABS_RX, ABS_RY],   0,  0.0)],
	[NormalizeAxisParam.new(-100, 100, [ABS_X, ABS_Y, ABS_RX, ABS_RY],-100, -1.0)],
	[NormalizeAxisParam.new(-100, 100, [ABS_X, ABS_Y, ABS_RX, ABS_RY], 100,  1.0)],
	[NormalizeAxisParam.new(-100, 100, [ABS_X, ABS_Y, ABS_RX, ABS_RY], -50, -0.5)],
	[NormalizeAxisParam.new(-100, 100, [ABS_X, ABS_Y, ABS_RX, ABS_RY],  50,  0.5)],

	# Test values for triggers with only positive values. These work differently
	# in that they should be expressed in distance from zero.
	[NormalizeAxisParam.new(   0, 300, [ABS_Z, ABS_RZ],    0,  0.0)],
	[NormalizeAxisParam.new(   0, 300, [ABS_Z, ABS_RZ],  300,  1.0)],
	[NormalizeAxisParam.new(   0, 300, [ABS_Z, ABS_RZ],  150,  0.5)],

	# Test values for triggers with positive/negative min/max ranges. These
	# work differently in that they should be expressed in distance from zero.
	[NormalizeAxisParam.new(-100, 100, [ABS_Z, ABS_RZ],    0,  0.0)],
	[NormalizeAxisParam.new(-100, 100, [ABS_Z, ABS_RZ], -100, -1.0)],
	[NormalizeAxisParam.new(-100, 100, [ABS_Z, ABS_RZ],  100,  1.0)],
	[NormalizeAxisParam.new(-100, 100, [ABS_Z, ABS_RZ],  -50, -0.5)],
	[NormalizeAxisParam.new(-100, 100, [ABS_Z, ABS_RZ],   50,  0.5)],
]

# Uses the axis minimum and maximum values to return a value from -1.0 - 1.0
# reflecting how far the axis has been pushed from a center point.
func test_normalize_axis(params=use_parameters(normalize_axis_params)) -> void:
	# Pull out the test params
	var param := params[0] as NormalizeAxisParam
	var axis_min := param.axis_min
	var axis_max := param.axis_max
	var events := param.get_events()
	var expected := param.normalized

	# Create a gamepad and set the appropriate axis values
	var gamepad := ManagedGamepad.new()
	set_gamepad_min_mid_max(gamepad, axis_min, axis_max)

	# Try to normalize the input events
	for event in events:
		var normalized := gamepad._normalize_axis(event)
		assert_eq(normalized, expected)


# Uses the axis minimum and maximum values to return a value from axis_min -> axis_max
# from a normalized axis value ranging from -1.0 - 1.0
func test_denormalize_axis(params=use_parameters(normalize_axis_params)) -> void:
	# Pull out the test params
	var param := params[0] as NormalizeAxisParam
	var axis_min := param.axis_min
	var axis_max := param.axis_max
	var events := param.get_events()
	var expected := param.normalized

	# Create a gamepad and set the appropriate axis values
	var gamepad := ManagedGamepad.new()
	set_gamepad_min_mid_max(gamepad, axis_min, axis_max)

	# Try to denormalize the input events
	for event in events:
		var denormalized := gamepad._denormalize_axis(event.code, expected)
		assert_eq(denormalized, event.value)


func create_event(type: int, code: int, value: int) -> InputDeviceEvent:
	var event := InputDeviceEvent.new()
	event.type = type
	event.code = code
	event.value = value
	return event


func create_events(type: int, codes: Array[int], value: int) -> Array[InputDeviceEvent]:
	var events: Array[InputDeviceEvent] = []
	for code in codes:
		var event := create_event(type, code, value)
		events.append(event)
	
	return events


func set_gamepad_min_mid_max(gamepad: ManagedGamepad, axis_min: int, axis_max: int) -> void:
	var axis_mid := (axis_max + axis_min)/2
	gamepad.abs_x_min = axis_min
	gamepad.abs_x_max = axis_max
	gamepad.abs_x_mid = axis_mid
	gamepad.abs_y_min = axis_min
	gamepad.abs_y_max = axis_max
	gamepad.abs_y_mid = axis_mid
	gamepad.abs_z_min = axis_min
	gamepad.abs_z_max = axis_max
	gamepad.abs_z_mid = axis_mid
	gamepad.abs_rx_min = axis_min
	gamepad.abs_rx_max = axis_max
	gamepad.abs_rx_mid = axis_mid
	gamepad.abs_ry_min = axis_min
	gamepad.abs_ry_max = axis_max
	gamepad.abs_ry_mid = axis_mid
	gamepad.abs_rz_min = axis_min
	gamepad.abs_rz_max = axis_max
	gamepad.abs_rz_mid = axis_mid


# Used for testing axis normalization.
class NormalizeAxisParam:
	var axis_min: int
	var axis_max: int
	var type: int = EV_ABS
	var codes: Array[int] = []
	var event_value: int
	var normalized: float
	
	func _init(ax_min: int, ax_max: int, ev_codes: Array[int], value: int, norm: float) -> void:
		axis_min = ax_min
		axis_max = ax_max
		codes = ev_codes
		event_value = value
		normalized = norm

	func create_event(code: int) -> InputDeviceEvent:
		var event := InputDeviceEvent.new()
		event.type = type
		event.code = code
		event.value = event_value
		return event

	func get_events() -> Array[InputDeviceEvent]:
		var events: Array[InputDeviceEvent] = []
		for code in codes:
			var event := create_event(code)
			events.append(event)
		return events

	func _to_string() -> String:
		return "AxisRange({0}-{1}) Codes({2}) EventValue({3}) NormalizedValue({4})".format(
			[axis_min, axis_max, " ".join(codes), event_value, normalized]
		)

extends EvdevEvent
class_name EvdevAbsEvent

enum AXIS {
	BOTH,     ## Event applies to both halfs of the axis (i.e. for mouse)
	POSITIVE, ## Event only applies to positive axis values
	NEGATIVE, ## Event only applies to negative axis values
}

@export_enum(
	"ABS_X",
	"ABS_Y",
	"ABS_Z",
	"ABS_RX",
	"ABS_RY",
	"ABS_RZ",
	"ABS_THROTTLE",
	"ABS_RUDDER",
	"ABS_WHEEL",
	"ABS_GAS",
	"ABS_BRAKE",
	"ABS_HAT0X",
	"ABS_HAT0Y",
	"ABS_HAT1X",
	"ABS_HAT1Y",
	"ABS_HAT2X",
	"ABS_HAT2Y",
	"ABS_HAT3X",
	"ABS_HAT3Y",
	"ABS_PRESSURE",
	"ABS_DISTANCE",
	"ABS_TILT_X",
	"ABS_TILT_Y",
	"ABS_TOOL_WIDTH",
	"ABS_VOLUME",
	"ABS_PROFILE",
	"ABS_MISC",
	"ABS_RESERVED",
	"ABS_MT_SLOT",
	"ABS_MT_TOUCH_MAJOR",
	"ABS_MT_TOUCH_MINOR",
	"ABS_MT_WIDTH_MAJOR",
	"ABS_MT_WIDTH_MINOR",
	"ABS_MT_ORIENTATION",
	"ABS_MT_POSITION_X",
	"ABS_MT_POSITION_Y",
	"ABS_MT_TOOL_TYPE",
	"ABS_MT_BLOB_ID",
	"ABS_MT_TRACKING_ID",
	"ABS_MT_PRESSURE",
	"ABS_MT_DISTANCE",
	"ABS_MT_TOOL_X",
	"ABS_MT_TOOL_Y",
	"ABS_MAX",
	"ABS_CNT",
)
var code: String:
	set(v):
		code = v
		input_device_event.code = input_device_event.get(v)

## Axis that this event applies to
# DEPRECATED
@export var axis: AXIS = AXIS.BOTH

func _init() -> void:
	super()
	input_device_event.type = InputDeviceEvent.EV_ABS


func is_binary_event() -> bool:
	return false

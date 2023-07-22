@icon("res://assets/editor-icons/integrated-circuit.svg")
@tool
extends MappableEvent
class_name EvdevEvent


## Defines a mapping of a single controller interface to another type of input
##
## GamepadMappings are part of a [GamepadProfile], which defines the input
## mapping of gamepad input to another type of input.

var type: int
## The evdev event ID source
var code: int
@export var value: int


func to_input_device_event() -> InputDeviceEvent:
	var event := InputDeviceEvent.new()
	event.code = code
	event.type = type
	event.value = value
	return event


## Create a new [EvdevEvent] from the given [InputDeviceEvent]
static func from_input_device_event(event: InputDeviceEvent) -> EvdevEvent:
	var evdev_event := EvdevEvent.new()
	evdev_event.type = event.type
	evdev_event.code = event.code
	evdev_event.value = event.value
	
	return evdev_event


# Customize editor properties that we expose.
func _get_property_list():
	var property_usage := PROPERTY_USAGE_DEFAULT
	var type_property := {
		"name": "type",
		"type": TYPE_INT,
		"usage": property_usage,  # See above assignment.
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(TYPES)
	}
	var code_property := {
		"name": "code",
		"type": TYPE_INT,
		"usage": property_usage,  # See above assignment.
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(CODES)
	}

	var properties := []
	properties.append(type_property)
	properties.append(code_property)

	return properties


const TYPES := [
	"EV_SYN",
	"EV_KEY",
	"EV_REL",
	"EV_ABS",
	"EV_MSC",
	"EV_SW",
	"EV_LED",
	"EV_SND",
	"EV_REP",
	"EV_FF",
	"EV_PWR",
	"EV_FF_STATUS",
	"EV_MAX",
	"EV_CNT",
]

const CODES := [
	"BTN_MISC",
	"BTN_0",
	"BTN_1",
	"BTN_2",
	"BTN_3",
	"BTN_4",
	"BTN_5",
	"BTN_6",
	"BTN_7",
	"BTN_8",
	"BTN_9",
	"BTN_MOUSE",
	"BTN_LEFT",
	"BTN_RIGHT",
	"BTN_MIDDLE",
	"BTN_SIDE",
	"BTN_EXTRA",
	"BTN_FORWARD",
	"BTN_BACK",
	"BTN_TASK",
	"BTN_JOYSTICK",
	"BTN_TRIGGER",
	"BTN_THUMB",
	"BTN_THUMB2",
	"BTN_TOP",
	"BTN_TOP2",
	"BTN_PINKIE",
	"BTN_BASE",
	"BTN_BASE2",
	"BTN_BASE3",
	"BTN_BASE4",
	"BTN_BASE5",
	"BTN_BASE6",
	"BTN_DEAD",
	"BTN_GAMEPAD",
	"BTN_SOUTH",
	"BTN_A",
	"BTN_EAST",
	"BTN_B",
	"BTN_C",
	"BTN_NORTH",
	"BTN_X",
	"BTN_WEST",
	"BTN_Y",
	"BTN_Z",
	"BTN_TL",
	"BTN_TR",
	"BTN_TL2",
	"BTN_TR2",
	"BTN_SELECT",
	"BTN_START",
	"BTN_MODE",
	"BTN_THUMBL",
	"BTN_THUMBR",
	"BTN_DIGI",
	"BTN_TOOL_PEN",
	"BTN_TOOL_RUBBER",
	"BTN_TOOL_BRUSH",
	"BTN_TOOL_PENCIL",
	"BTN_TOOL_AIRBRUSH",
	"BTN_TOOL_FINGER",
	"BTN_TOOL_MOUSE",
	"BTN_TOOL_LENS",
	"BTN_TOOL_QUINTTAP",
	"BTN_STYLUS3",
	"BTN_TOUCH",
	"BTN_STYLUS",
	"BTN_STYLUS2",
	"BTN_TOOL_DOUBLETAP",
	"BTN_TOOL_TRIPLETAP",
	"BTN_TOOL_QUADTAP",
	"BTN_WHEEL",
	"BTN_GEAR_DOWN",
	"BTN_GEAR_UP",
	"BTN_DPAD_UP",
	"BTN_DPAD_DOWN",
	"BTN_DPAD_LEFT",
	"BTN_DPAD_RIGHT",
	"BTN_TRIGGER_HAPPY",
	"BTN_TRIGGER_HAPPY1",
	"BTN_TRIGGER_HAPPY2",
	"BTN_TRIGGER_HAPPY3",
	"BTN_TRIGGER_HAPPY4",
	"BTN_TRIGGER_HAPPY5",
	"BTN_TRIGGER_HAPPY6",
	"BTN_TRIGGER_HAPPY7",
	"BTN_TRIGGER_HAPPY8",
	"BTN_TRIGGER_HAPPY9",
	"BTN_TRIGGER_HAPPY10",
	"BTN_TRIGGER_HAPPY11",
	"BTN_TRIGGER_HAPPY12",
	"BTN_TRIGGER_HAPPY13",
	"BTN_TRIGGER_HAPPY14",
	"BTN_TRIGGER_HAPPY15",
	"BTN_TRIGGER_HAPPY16",
	"BTN_TRIGGER_HAPPY17",
	"BTN_TRIGGER_HAPPY18",
	"BTN_TRIGGER_HAPPY19",
	"BTN_TRIGGER_HAPPY20",
	"BTN_TRIGGER_HAPPY21",
	"BTN_TRIGGER_HAPPY22",
	"BTN_TRIGGER_HAPPY23",
	"BTN_TRIGGER_HAPPY24",
	"BTN_TRIGGER_HAPPY25",
	"BTN_TRIGGER_HAPPY26",
	"BTN_TRIGGER_HAPPY27",
	"BTN_TRIGGER_HAPPY28",
	"BTN_TRIGGER_HAPPY29",
	"BTN_TRIGGER_HAPPY30",
	"BTN_TRIGGER_HAPPY31",
	"BTN_TRIGGER_HAPPY32",
	"BTN_TRIGGER_HAPPY33",
	"BTN_TRIGGER_HAPPY34",
	"BTN_TRIGGER_HAPPY35",
	"BTN_TRIGGER_HAPPY36",
	"BTN_TRIGGER_HAPPY37",
	"BTN_TRIGGER_HAPPY38",
	"BTN_TRIGGER_HAPPY39",
	"BTN_TRIGGER_HAPPY40",
	"REL_X",
	"REL_Y",
	"REL_Z",
	"REL_RX",
	"REL_RY",
	"REL_RZ",
	"REL_HWHEEL",
	"REL_DIAL",
	"REL_WHEEL",
	"REL_MISC",
	"REL_RESERVED",
	"REL_WHEEL_HI_RES",
	"REL_HWHEEL_HI_RES",
	"REL_MAX",
	"REL_CNT",
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
	"LED_NUML",
	"LED_CAPSL",
	"LED_SCROLLL",
	"LED_COMPOSE",
	"LED_KANA",
	"LED_SLEEP",
	"LED_SUSPEND",
	"LED_MUTE",
	"LED_MISC",
	"LED_MAIL",
	"LED_CHARGING",
	"LED_MAX",
	"LED_CNT",
	"REP_DELAY",
	"REP_PERIOD",
	"REP_MAX",
	"REP_CNT",
]

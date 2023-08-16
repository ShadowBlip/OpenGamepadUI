extends EvdevEvent
class_name EvdevRelEvent

@export_enum(
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
)
var code: String:
	set(v):
		code = v
		if v == "":
			return
		input_device_event.code = input_device_event.get(v)


func _init() -> void:
	super()
	input_device_event.type = InputDeviceEvent.EV_REL


func is_binary_event() -> bool:
	return false

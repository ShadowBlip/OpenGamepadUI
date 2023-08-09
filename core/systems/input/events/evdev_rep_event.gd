extends EvdevEvent
class_name EvdevRepEvent

@export_enum(
	"REP_DELAY",
	"REP_PERIOD",
	"REP_MAX",
	"REP_CNT",
)
var code: String:
	set(v):
		code = v
		if v == "":
			return
		input_device_event.code = input_device_event.get(v)


func _init() -> void:
	super()
	input_device_event.type = InputDeviceEvent.EV_REP

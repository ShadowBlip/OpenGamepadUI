extends EvdevEvent
class_name EvdevSynEvent

@export_enum(
	"SYN_REPORT",
	"SYN_CONFIG",
	"SYN_MT_REPORT",
	"SYN_DROPPED",
	"SYN_MAX",
	"SYN_CNT",
)
var code: String:
	set(v):
		code = v
		if v == "":
			return
		input_device_event.code = input_device_event.get(v)


func _init() -> void:
	super()
	input_device_event.type = InputDeviceEvent.EV_SYN

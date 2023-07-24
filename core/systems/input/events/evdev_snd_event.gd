extends EvdevEvent
class_name EvdevSndEvent

@export_enum(
	"SND_CLICK",
	"SND_BELL",
	"SND_TONE",
	"SND_MAX",
	"SND_CNT",
)
var code: String:
	set(v):
		code = v
		input_device_event.code = input_device_event.get(v)


func _init() -> void:
	super()
	input_device_event.type = InputDeviceEvent.EV_SND

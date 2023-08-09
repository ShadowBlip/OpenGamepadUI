extends EvdevEvent
class_name EvdevMscEvent

@export_enum(
	"MSC_SERIAL",
	"MSC_PULSELED",
	"MSC_GESTURE",
	"MSC_RAW",
	"MSC_SCAN",
	"MSC_TIMESTAMP",
	"MSC_MAX",
	"MSC_CNT",
)
var code: String:
	set(v):
		code = v
		if v == "":
			return
		input_device_event.code = input_device_event.get(v)


func _init() -> void:
	super()
	input_device_event.type = InputDeviceEvent.EV_MSC

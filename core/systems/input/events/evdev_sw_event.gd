extends EvdevEvent
class_name EvdevSwEvent

@export_enum(
	"SW_LID",
	"SW_TABLET_MODE",
	"SW_HEADPHONE_INSERT",
	"SW_RFKILL_ALL",
	"SW_RADIO",
	"SW_MICROPHONE_INSERT",
	"SW_DOCK",
	"SW_LINEOUT_INSERT",
	"SW_JACK_PHYSICAL_INSERT",
	"SW_VIDEOOUT_INSERT",
	"SW_CAMERA_LENS_COVER",
	"SW_KEYPAD_SLIDE",
	"SW_FRONT_PROXIMITY",
	"SW_ROTATE_LOCK",
	"SW_LINEIN_INSERT",
	"SW_MUTE_DEVICE",
	"SW_PEN_INSERTED",
	"SW_MACHINE_COVER",
	"SW_MAX",
	"SW_CNT",
)
var code: String:
	set(v):
		code = v
		input_device_event.code = input_device_event.get(v)


func _init() -> void:
	super()
	input_device_event.type = InputDeviceEvent.EV_SW

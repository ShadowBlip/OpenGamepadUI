extends EvdevEvent
class_name EvdevLedEvent

@export_enum(
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
)
var code: String:
	set(v):
		code = v
		if v == "":
			return
		input_device_event.code = input_device_event.get(v)


func _init() -> void:
	super()
	input_device_event.type = InputDeviceEvent.EV_LED

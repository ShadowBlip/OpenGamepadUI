extends HBoxContainer

const icon_charging = preload("res://assets/ui/icons/battery-charging.svg")
const icon_full = preload("res://assets/ui/icons/battery-full.svg")
const icon_high = preload("res://assets/ui/icons/battery-75.svg")
const icon_half = preload("res://assets/ui/icons/battery-half.svg")
const icon_low = preload("res://assets/ui/icons/battery-low.svg")
const icon_empty = preload("res://assets/ui/icons/battery-empty.svg")

const no_battery_names := ["battery-missing-symbolic"]

var power_manager := load("res://core/systems/power/power_manager.tres") as UPowerInstance
var display_device := power_manager.get_display_device()

var logger := Log.get_logger("BatteryContainer", Log.LEVEL.INFO)

@onready var battery_icon: TextureRect = $%BatteryIcon
@onready var battery_label: Label = $%BatteryLabel


func _ready():
	if not display_device:
		logger.debug("No battery detected. nothing to do.")
		visible = false
		return

	if display_device.icon_name in no_battery_names:
		logger.debug("No battery detected. nothing to do.")
		visible = false
		return

	_on_update_device(display_device)
	display_device.updated.connect(_on_update_device.bind(display_device))


func _on_update_device(item: UPowerDevice):
	var capacity := item.percentage
	var state := item.state
	battery_icon.texture = get_capacity_texture(capacity, state)
	battery_label.text = str(int(capacity))+"%"
	if capacity > 5:
		battery_icon.modulate = Color(1, 1, 1)
	else:
		battery_icon.modulate = Color(1, 0, 0)


## Returns the texture reflecting the given battery capacity
static func get_capacity_texture(capacity: int, state: int) -> Texture2D:
	if state in [UPowerDevice.STATE_CHARGING, UPowerDevice.STATE_FULLY_CHARGED]:
		return icon_charging
	if capacity >= 90:
		return icon_full
	if capacity >= 65:
		return icon_high
	if capacity >= 40:
		return icon_half
	if capacity >= 20:
		return icon_low
	return icon_empty

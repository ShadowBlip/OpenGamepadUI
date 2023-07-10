extends HBoxContainer

const icon_charging = preload("res://assets/ui/icons/battery-charging.svg")
const icon_full = preload("res://assets/ui/icons/battery-full.svg")
const icon_high = preload("res://assets/ui/icons/battery-75.svg")
const icon_half = preload("res://assets/ui/icons/battery-half.svg")
const icon_low = preload("res://assets/ui/icons/battery-low.svg")
const icon_empty = preload("res://assets/ui/icons/battery-empty.svg")

var power_manager := load("res://core/systems/power/power_manager.tres") as PowerManager
var batteries : Array[PowerManager.Device]

var logger := Log.get_logger("BatteryContainer", Log.LEVEL.INFO)

@onready var battery_icon: TextureRect = $%BatteryIcon
@onready var battery_label: Label = $%BatteryLabel


func _ready():
	batteries = power_manager.get_devices_by_type(PowerManager.DEVICE_TYPE.BATTERY)
	if batteries.size() > 1:
		logger.warn("You somehow have more than one battery. We don't know what to do with that.")
	if batteries.size() == 0:
		logger.debug("No battery detected. nothing to do.")
		visible = false
		return

	var battery := batteries[0]
	_on_update_device(battery)
	battery.updated.connect(_on_update_device.bind(battery))


func _on_update_device(item: PowerManager.Device):
	var capacity := item.percentage
	var state := item.state
	battery_icon.texture = get_capacity_texture(capacity, state)
	battery_label.text = str(capacity)+"%"
	if capacity > 5:
		battery_icon.modulate = Color(1, 1, 1)
	else:
		battery_icon.modulate = Color(1, 0, 0)


## Returns the texture reflecting the given battery capacity
static func get_capacity_texture(capacity: int, state: PowerManager.DEVICE_STATE) -> Texture2D:
	if state in [PowerManager.DEVICE_STATE.CHARGING, PowerManager.DEVICE_STATE.FULLY_CHARGED]:
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

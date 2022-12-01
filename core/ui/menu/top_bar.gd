extends Control

@onready var battery: String = Battery.find_battery_path()
@onready var time_label: Label = $MarginContainer/HBoxContainer/TimeLabel
@onready var battery_label: Label = $MarginContainer/HBoxContainer/BatteryLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var time_timer: Timer = Timer.new()
	time_timer.timeout.connect(_on_update_time)
	time_timer.timeout.connect(_on_update_battery)
	time_timer.autostart = true
	add_child(time_timer)
	_on_update_time()
	_on_update_battery()


# Updates the battery capacity on timer timeout
func _on_update_battery():
	var current_capacity: int = Battery.get_capacity(battery)
	battery_label.text = "{0}%".format([current_capacity])


# Updates the current time on timer timeout
func _on_update_time():
	# year, month, day, weekday, hour, minute, second
	var time = Time.get_datetime_dict_from_system()
	time_label.text = _format_time(time)
	
	
func _format_time(time: Dictionary) -> String:
	time["meridium"] = "am"
	if time["hour"] > 11:
		time["meridium"] = "pm"
	if time["hour"] > 12:
		time["hour"] -= 12
	
	# Pad our minutes and hours
	time["minute"] = "%02d" % time["minute"]
	time["hour"] = "%02d" % time["hour"]
	
	return "{hour}:{minute}{meridium}".format(time)

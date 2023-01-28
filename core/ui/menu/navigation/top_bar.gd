extends Control

var  main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var  in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var  qam_state := preload("res://assets/state/states/quick_access_menu.tres") as State

var panel_alpha_normal := 156
var panel_alpha_solid := 255

@onready var battery: String = Battery.find_battery_path()
@onready var time_label: Label = $%TimeLabel
@onready var battery_label: Label = $%BatteryLabel
@onready var search_bar := $%SearchBar
@onready var panel := $%Panel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Update the panel alpha during in-game and main menus
	panel.modulate.a8 = panel_alpha_normal
	main_menu_state.state_entered.connect(_on_game_menu_entered)
	main_menu_state.state_exited.connect(_on_game_menu_exited)
	in_game_menu_state.state_entered.connect(_on_game_menu_entered)
	in_game_menu_state.state_exited.connect(_on_game_menu_exited)
	qam_state.state_entered.connect(_on_game_menu_entered)
	qam_state.state_exited.connect(_on_game_menu_exited)

	# Create a timer to update the time and battery percent
	var time_timer: Timer = Timer.new()
	time_timer.timeout.connect(_on_update_time)
	time_timer.timeout.connect(_on_update_battery)
	time_timer.autostart = true
	add_child(time_timer)
	_on_update_time()
	_on_update_battery()


func _on_game_menu_entered(_from: State) -> void:
	panel.modulate.a8 = panel_alpha_solid


func _on_game_menu_exited(to: State) -> void:
	if to in [in_game_menu_state, main_menu_state, qam_state]:
		return
	panel.modulate.a8 = panel_alpha_normal


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

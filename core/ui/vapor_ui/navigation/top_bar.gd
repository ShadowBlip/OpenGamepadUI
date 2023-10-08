extends Control

const thread := preload("res://core/systems/threading/thread_pool.tres")

var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var quick_bar_menu_state := preload("res://assets/state/states/quick_bar_menu.tres") as State

var battery_capacity := -1
var panel_alpha_normal := 156
var panel_alpha_solid := 255

@onready var battery: String = Battery.find_battery_path()
@onready var time_label: Label = $%TimeLabel
@onready var battery_container: HBoxContainer = $%BatteryContainer
@onready var battery_icon: TextureRect = $%BatteryIcon
@onready var battery_label: Label = $%BatteryLabel
@onready var search_bar := $%SearchBar
@onready var panel := $%Panel
@onready var network_icon := $%NetworkIcon as TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thread.start()

	# Update the panel alpha during in-game and main menus
	panel.modulate.a8 = panel_alpha_normal
	main_menu_state.state_entered.connect(_on_game_menu_entered)
	main_menu_state.state_exited.connect(_on_game_menu_exited)
	in_game_menu_state.state_entered.connect(_on_game_menu_entered)
	in_game_menu_state.state_exited.connect(_on_game_menu_exited)
	quick_bar_menu_state.state_entered.connect(_on_game_menu_entered)
	quick_bar_menu_state.state_exited.connect(_on_game_menu_exited)

	# Create a timer to update the time
	var time_timer: Timer = Timer.new()
	time_timer.timeout.connect(_on_update_time)
	time_timer.autostart = true
	add_child(time_timer)
	_on_update_time()

	# Create a timer to check wifi signal strength and battery percent
	var wifi_timer := Timer.new()
	wifi_timer.timeout.connect(_on_wifi_update)
	wifi_timer.timeout.connect(_on_update_battery)
	wifi_timer.wait_time = 60
	wifi_timer.autostart = true
	add_child(wifi_timer)
	_on_wifi_update()
	_on_update_battery()
	battery_capacity = Battery.get_capacity(battery)
	
	# Create a timer to check battery status
	var battery_timer := Timer.new()
	battery_timer.timeout.connect(_on_update_battery_status)
	battery_timer.wait_time = 5
	battery_timer.autostart = true
	add_child(battery_timer)
	_on_update_battery_status()
	

func _on_game_menu_entered(_from: State) -> void:
	panel.modulate.a8 = panel_alpha_solid


func _on_game_menu_exited(to: State) -> void:
	if to in [in_game_menu_state, main_menu_state, quick_bar_menu_state]:
		return
	panel.modulate.a8 = panel_alpha_normal


# Updates the wifi signal strength on timer timeout
func _on_wifi_update() -> void:
	var get_ap := func() -> NetworkManager.WifiAP:
		return NetworkManager.get_current_access_point()
	var current_ap := await thread.exec(get_ap) as NetworkManager.WifiAP
	var strength := 0
	if current_ap:
		strength = current_ap.strength
	network_icon.texture = NetworkManager.get_strength_texture(strength)


## Updates the battery status on timer timeout
func _on_update_battery_status():
	if battery == "":
		if battery_container.visible:
			battery_container.visible = false
		return
	var status: int = Battery.get_status(battery)
	battery_icon.texture = Battery.get_capacity_texture(battery_capacity, status)
	if status < Battery.STATUS.CHARGING and battery_capacity < 10:
		battery_icon.modulate = Color(255, 0, 0)
	else:
		battery_icon.modulate = Color(255, 255, 255)


# Updates the battery capacity on timer timeout
func _on_update_battery():
	var get_capacity := func() -> int:
		return Battery.get_capacity(battery)
	var current_capacity: int = await thread.exec(get_capacity)
	battery_capacity = current_capacity
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

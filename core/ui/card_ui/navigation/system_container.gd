extends HBoxContainer

const thread := preload("res://core/systems/threading/thread_pool.tres")

var battery_capacity := -1

@onready var battery: String = Battery.find_battery_path()
@onready var battery_container: HBoxContainer = $%BatteryContainer
@onready var battery_icon: TextureRect = $%BatteryIcon
@onready var battery_label: Label = $%BatteryLabel
@onready var network_icon := $%NetworkIcon as TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thread.start()

	# Create a timer to check wifi signal strength and battery percent
	var wifi_timer := Timer.new()
	wifi_timer.timeout.connect(_on_wifi_update)
	wifi_timer.wait_time = 60
	wifi_timer.autostart = true
	add_child(wifi_timer)
	_on_wifi_update()
	battery_capacity = Battery.get_capacity(battery)
	
	# Create a timer to check battery status
	var battery_timer := Timer.new()
	battery_timer.timeout.connect(_on_update_battery_status)
	battery_timer.timeout.connect(_on_update_battery)
	battery_timer.wait_time = 3
	battery_timer.autostart = true
	add_child(battery_timer)
	_on_update_battery()
	_on_update_battery_status()


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

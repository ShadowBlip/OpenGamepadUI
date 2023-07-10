extends HBoxContainer

const thread := preload("res://core/systems/threading/thread_pool.tres")

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


# Updates the wifi signal strength on timer timeout
func _on_wifi_update() -> void:
	var get_ap := func() -> NetworkManager.WifiAP:
		return NetworkManager.get_current_access_point()
	var current_ap := await thread.exec(get_ap) as NetworkManager.WifiAP
	var strength := 0
	if current_ap:
		strength = current_ap.strength
	network_icon.texture = NetworkManager.get_strength_texture(strength)

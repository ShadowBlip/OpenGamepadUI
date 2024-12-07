extends HBoxContainer

var network_manager := load("res://core/systems/network/network_manager.tres") as NetworkManagerInstance

@onready var network_icon := $%NetworkIcon as TextureRect

var current_access_point: NetworkAccessPoint


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the visibility of the network icon depending on if networking is available
	network_manager.started.connect(_on_networking_available)
	network_manager.stopped.connect(_on_networking_available)
	_on_networking_available()

	# Listen for active connection changes to determine what icon to display
	network_manager.primary_connection_changed.connect(_on_primary_change)
	_on_primary_change(network_manager.primary_connection)


func _on_networking_available() -> void:
	network_icon.visible = network_manager.is_running()
	

func _on_primary_change(conn: NetworkActiveConnection) -> void:
	if current_access_point:
		current_access_point.strength_changed.disconnect(_on_wifi_strength_changed)
	current_access_point = null
	if not conn:
		# No active connection
		network_icon.texture = NetworkManager.no_network
		return

	var devices := conn.devices
	if devices.is_empty():
		# No devices associated with connection
		network_icon.texture = NetworkManager.no_network
		return

	# Set the icon based on the type of device
	var device := devices[0]
	if not device.wireless:
		network_icon.texture = NetworkManager.ethernet
		return
	
	# Set the texture based on wifi state
	current_access_point = device.wireless.active_access_point
	if not current_access_point:
		network_icon.texture = NetworkManager.bar_0
		return
	network_icon.texture = NetworkManager.get_strength_texture(current_access_point.strength)
	
	# Update the wifi strength
	current_access_point.strength_changed.connect(_on_wifi_strength_changed)


func _on_wifi_strength_changed(strength: int) -> void:
	network_icon.texture = NetworkManager.get_strength_texture(strength)

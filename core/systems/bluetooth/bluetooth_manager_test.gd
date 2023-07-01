extends Test

var timer := Timer.new()
var bluetooth := load("res://core/systems/bluetooth/bluetooth_manager.tres") as BluetoothManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if bluetooth.start_discovery() != OK:
		return

	timer.autostart = true
	timer.timeout.connect(_on_timeout)
	add_child(timer)

func _on_timeout() -> void:
	var devices := bluetooth.get_discovered_devices()
	for device in devices:
		print("Discovered device: ", device)
		print(device.address)

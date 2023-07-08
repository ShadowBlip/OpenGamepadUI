extends Test

var timer := Timer.new()
var bluetooth := load("res://core/systems/bluetooth/bluetooth_manager.tres") as BluetoothManager
var adapter := bluetooth.get_adapter()
var devices := {}
var device_nodes := {}

@onready var container := $%VBoxContainer
@onready var enable_button := $%CheckButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.autostart = true
	timer.timeout.connect(_on_timeout)
	add_child(timer)

	# Discover bluetooth devices when toggled
	var on_press := func(pressed: bool):
		if pressed:
			adapter.start_discovery()
			return
		adapter.stop_discovery()
	enable_button.toggled.connect(on_press)
	

func _on_timeout() -> void:
	var discovered := bluetooth.get_discovered_devices()
	
	# Add buttons for new devices
	devices = {}
	for device in discovered:
		var address := device.address
		devices[address] = device
		if address in device_nodes:
			continue
		
		# Create the button for the device
		var button := Button.new()
		button.text = "Device: " + device.name + " (" + address + ")"
		device_nodes[address] = button
		
		# Add the button
		var on_pressed := func():
			if not device.paired:
				device.pair()
		button.pressed.connect(on_pressed)
		container.add_child(button)
		
	var addresses := devices.keys()
	
	# Remove devices no longer there
	for address in device_nodes.keys():
		if address in addresses:
			continue
		var node := device_nodes[address] as Node
		node.queue_free()
		device_nodes.erase(address)

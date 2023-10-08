extends Test


var hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hardware_manager.start_gpu_watch()
	print(hardware_manager.cards)
	print(hardware_manager.bios)
	print(hardware_manager.cpu)
	print(hardware_manager.gpu)
	print(hardware_manager.kernel)
	print(hardware_manager.product_name)
	print(hardware_manager.vendor_name)

	# Listen for port state changes
	for card in hardware_manager.cards:
		for port in card.get_ports():
			port.changed.connect(_on_port_changed.bind(port))


func _on_port_changed(port: DRMCardPort) -> void:
	print("Port changed: ", port.name, " Status: ", port.status)

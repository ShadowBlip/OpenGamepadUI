extends Control

const system_thread := preload("res://core/systems/threading/system_thread.tres")

var bluetooth_manager := load("res://core/systems/bluetooth/bluetooth_manager.tres") as BluetoothManager
var connecting := false
var discovered_devices: Array[BluetoothManager.BluetoothDevice] = []

@onready var no_net_label := $%NoBluetoothLabel
@onready var bt_tree := $%BluetoothDeviceTree as Tree

var logger := Log.get_logger("BluetoothSettings", Log.LEVEL.DEBUG)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bluetooth_manager.start(true)
	if not bluetooth_manager.supports_bluetooth():
		no_net_label.visible = true
		return
	visibility_changed.connect(_on_visible_changed)
	bt_tree.item_activated.connect(_on_bt_selected)
	bt_tree.create_item()
	bluetooth_manager.devices_updated.connect(_on_discovered_devices)
	_on_visible_changed()


func _process(delta):
	for device in discovered_devices:
		logger.debug(str(device))


func _on_visible_changed() -> void:
	set_process(self.visible)


func _on_bt_selected() -> void:
	return # Do a popup for pair/unpair connect/disconnect


func _on_discovered_devices(devices: Array[BluetoothManager.BluetoothDevice]) -> void:
	discovered_devices = devices
	for device in discovered_devices:
		logger.debug(str(device))


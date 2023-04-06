extends Control

const system_thread := preload("res://core/systems/threading/system_thread.tres")

var connecting := false
@onready var no_net_label := $%NoBluetoothLabel
@onready var bt_tree := $%BluetoothDeviceTree as Tree


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not BluetoothManager.supports_bluetooth():
		no_net_label.visible = true
		return

	system_thread.start()
	visibility_changed.connect(_on_visible_changed)
	bt_tree.item_activated.connect(_on_bt_selected)
	bt_tree.create_item()


func _on_visible_changed() -> void:
	_refresh_devices()


func _on_bt_selected() -> void:
	return

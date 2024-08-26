@icon("res://assets/editor-icons/bluetooth.svg")
extends Node
class_name BluetoothManager

## BluetoothManager interfaces with the bluetooth system
##
## This node is used to drive the bluetooth instance forward by calling its
## 'process()' method every frame to dispatch signals.

@export var instance: BluezInstance = load("res://core/systems/bluetooth/bluetooth_manager.tres")


func _process(_delta: float) -> void:
	if not instance:
		return
	instance.process()

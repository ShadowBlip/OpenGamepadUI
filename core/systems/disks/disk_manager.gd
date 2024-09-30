extends Node
class_name DiskManager


@export var instance: UDisks2Instance = load("res://core/systems/disks/disk_manager.tres") as UDisks2Instance


func _process(_delta: float) -> void:
	if not instance:
		return
	instance.process()

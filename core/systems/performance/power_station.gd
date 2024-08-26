@icon("res://assets/editor-icons/game-icons--power-generator.svg")
extends Node
class_name PowerStation

## Proxy interface to PowerStation over DBus
##
## Provides wrapper classes and methods for interacting with PowerStation over
## DBus to control CPU and GPU performance.

@export var instance: PowerStationInstance = load("res://core/systems/performance/power_station.tres") as PowerStationInstance

# Keep a reference to instances so they are not cleaned up automatically
var _cpu: Cpu
var _gpu: Gpu
var logger := Log.get_logger("PowerStation")


func _ready() -> void:
	_cpu = instance.get_cpu()
	_gpu = instance.get_gpu()


func _process(_delta: float) -> void:
	if not instance:
		return
	instance.process()

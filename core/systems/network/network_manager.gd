@icon("res://assets/ui/icons/iconoir--network-solid.svg")
extends Node
class_name NetworkManager

## Manages NetworkManager.
##
## The [NetworkManager] class is responsible for loading a [NetworkManagerInstance] and
## calling its 'process()' method each frame.

const bar_0 := preload("res://assets/ui/icons/wifi-none.svg")
const bar_1 := preload("res://assets/ui/icons/wifi-low.svg")
const bar_2 := preload("res://assets/ui/icons/wifi-medium.svg")
const bar_3 := preload("res://assets/ui/icons/wifi-high.svg")
const no_network := preload("res://assets/ui/icons/tabler--network-off.svg")
const ethernet := preload("res://assets/ui/icons/mdi--ethernet.svg")

@export var instance: NetworkManagerInstance = load("res://core/systems/network/network_manager.tres") as NetworkManagerInstance


## Returns the texture reflecting the given wifi strength
static func get_strength_texture(strength: int) -> Texture2D:
	if strength >= 80:
		return bar_3
	if strength >= 60:
		return bar_2
	if strength >= 40:
		return bar_1
	return bar_0


func _process(_delta: float) -> void:
	if not instance:
		return
	instance.process()

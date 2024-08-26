@icon("res://assets/editor-icons/streamline--desktop-game-solid.svg")
extends Node
class_name Gamescope

## Manages gamescope.
##
## The [Gamescope] class is responsible for loading a [GamescopeInstance] and
## calling its 'process()' method each frame.

@export var instance: GamescopeInstance = load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance

# Keep a reference to xwayland instances so they are not cleaned up automatically
var _xwaylands: Array[GamescopeXWayland]
var logger := Log.get_logger("Gamescope")


func _ready() -> void:
	_xwaylands = instance.get_xwaylands()
	if _xwaylands.is_empty():
		logger.warn("Gamescope not detected. Unexpected behavior expected.")


func _process(_delta: float) -> void:
	if not instance:
		return
	instance.process()

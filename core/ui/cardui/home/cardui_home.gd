extends Control

@onready var container := $%CardContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	container.get_child(1).grab_focus.call_deferred()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

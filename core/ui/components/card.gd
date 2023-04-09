@tool
extends Control

@onready var animation_player := $%AnimationPlayer
@onready var texture := $%TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	texture.mouse_entered.connect(_on_focus)
	texture.mouse_exited.connect(_on_unfocus)
	texture.position = Vector2.ZERO
	animation_player.play("RESET")
	
	# Set shader parameters
	texture.material.set_shader_parameter("corder_radius", 80)
	
	var parent := get_parent()
	if parent and parent is Container:
		parent.queue_sort()


func _on_focus() -> void:
	animation_player.play("focus_entered")


func _on_unfocus() -> void:
	animation_player.play("focus_exited")

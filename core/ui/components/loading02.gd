@tool
extends Control

@onready var sprite := $Sprite2D as Sprite2D
@onready var animation_player := $Sprite2D/AnimationPlayer as AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if visible:
		animation_player.play("play")
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if not animation_player:
		return
	if visible:
		set_process(true)
		animation_player.play("play")
		return
	animation_player.stop()
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var sprite_scale := 1 / (sprite.texture.get_height() / size.y)
	sprite.offset = size / 2 / sprite_scale
	sprite.scale = Vector2(sprite_scale, sprite_scale)

@tool
extends Control

@onready var sprite := $Sprite2D as Sprite2D
@onready var animation_player := $Sprite2D/AnimationPlayer as AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_visible_in_tree():
		set_process(true)
		animation_player.play("play")
	else:
		set_process(false)
		animation_player.stop()
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if not animation_player:
		return
	if is_visible_in_tree():
		set_process(true)
		animation_player.play("play")
		return
	animation_player.stop()
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var sprite_scale := 1 / (sprite.texture.get_height() / size.y)
	var new_offset := size / 2 / sprite_scale
	if new_offset != sprite.offset:
		sprite.offset = new_offset
	var new_scale := Vector2(sprite_scale, sprite_scale)
	if new_scale != sprite.scale:
		sprite.scale = new_scale

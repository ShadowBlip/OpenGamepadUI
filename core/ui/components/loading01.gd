extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_rect.pivot_offset = texture_rect.size/2
	if visible:
		animation_player.play("loading")
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if not animation_player:
		return
	if visible:
		animation_player.play("loading")
		return
	animation_player.stop()

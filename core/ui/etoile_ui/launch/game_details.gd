extends Control

var tween: Tween
var state := preload("res://assets/state/states/game_launcher.tres") as State
var boxart_manager := preload("res://core/global/boxart_manager.tres") as BoxArtManager

@onready var logo := %Logo as TextureRect


func _ready() -> void:
	state.state_entered.connect(_on_state_entered)
	state.state_exited.connect(_on_state_exited)
	state.refreshed.connect(_on_state_refreshed)


func _on_state_entered(from: State) -> void:
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()
	tween = tree.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "size_flags_stretch_ratio", 2.0, 1.0)


func _on_state_exited(to: State) -> void:
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()
	tween = tree.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "size_flags_stretch_ratio", 0.0, 1.0)


func _on_state_refreshed() -> void:
	if not state.has_meta("library_item"):
		return
	var library_item := state.get_meta("library_item") as LibraryItem
	var texture := await boxart_manager.get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.LOGO)
	logo.texture = texture

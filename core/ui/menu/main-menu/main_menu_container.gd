extends HBoxContainer

var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu_state.state_entered.connect(_on_state_entered)
	main_menu_state.state_exited.connect(_on_state_exited)
	in_game_menu_state.state_entered.connect(_on_state_entered)
	in_game_menu_state.state_exited.connect(_on_state_exited)


func _on_state_entered(_from: State) -> void:
	_animate(true)


func _on_state_exited(_to: State) -> void:
	_animate(false)


func _animate(should_show: bool) -> void:
	var player: AnimationPlayer = $AnimationPlayer
	if should_show:
		player.play("show")
	else:
		player.play("hide")

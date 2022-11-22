extends HBoxContainer

@onready var state_mgr: StateManager = get_node("/root/Main/StateManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	state_mgr.state_changed.connect(_on_state_changed)


func _on_state_changed(from: int, to: int) -> void:
	var should_show = to == StateManager.State.MAIN_MENU or to == StateManager.State.IN_GAME_MENU
	_animate(should_show)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _animate(should_show: bool) -> void:
	var player: AnimationPlayer = $AnimationPlayer
	if should_show:
		player.play("show")
	else:
		player.play("hide")

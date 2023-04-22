extends PanelContainer

var tween: Tween
var library_state := load("res://assets/state/states/library.tres") as State
var default_size := Vector2(custom_minimum_size.x, custom_minimum_size.y)

@onready var tabs_container := $%LibraryTabsContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tabs_container.visible = false
	tabs_container.modulate = Color(1, 1, 1, 0)
	library_state.state_entered.connect(_on_library_entered)
	library_state.state_exited.connect(_on_library_exited)


func _on_library_entered(_from: State) -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "custom_minimum_size", Vector2(default_size.x + tabs_container.size.x, default_size.y), 0.2)
	tween.tween_property(tabs_container, "visible", true, 0)
	tween.tween_property(tabs_container, "modulate", Color(1, 1, 1, 1), 0.2)


func _on_library_exited(to: State) -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(tabs_container, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(tabs_container, "visible", false, 0)
	tween.tween_property(self, "custom_minimum_size", Vector2(default_size.x - tabs_container.size.x, default_size.y), 0.2)


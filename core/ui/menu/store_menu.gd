extends Control

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var store_manager: StoreManager = get_node("/root/Main/StoreManager")
var poster_scene: PackedScene = preload("res://core/ui/components/poster.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Clear the template buttons
	var grid: GridContainer = $MarginContainer/GridContainer
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	
	# Listen for stores that register
	store_manager.store_registered.connect(_on_store_registered)
	state_manager.state_changed.connect(_on_state_changed)
	visible = false


# When a store is registered, add an entry to the stores menu
func _on_store_registered(store: Store) -> void:
	var grid: GridContainer = $MarginContainer/GridContainer
	
	# Build the poster to display
	var poster: TextureButton = poster_scene.instantiate()
	poster.set_layout(poster.LAYOUT_LANDSCAPE)
	var img: Texture2D = load(store.store_image)
	poster.texture_normal = img
	var label: Label = poster.get_node("Label")
	label.text = store.store_name

	grid.add_child(poster)


func _on_state_changed(from: StateManager.State, to: StateManager.State) -> void:
	visible = state_manager.has_state(StateManager.State.STORE)
	if not visible:
		return
	if visible and to == StateManager.State.IN_GAME:
		state_manager.remove_state(StateManager.State.STORE)
	var grid: GridContainer = $MarginContainer/GridContainer
	for child in grid.get_children():
		child.grab_focus.call_deferred()
		break

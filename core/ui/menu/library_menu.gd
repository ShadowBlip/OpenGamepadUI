extends Control

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var library_manager: LibraryManager = get_node("/root/Main/LibraryManager")
@onready var all_games_grid: HFlowContainer = $"TabContainer/All Games/MarginContainer/HFlowContainer"

var poster_scene: PackedScene = preload("res://core/ui/components/poster.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)
	visible = false


func _on_state_changed(from: StateManager.State, to: StateManager.State) -> void:
	visible = state_manager.has_state(StateManager.State.LIBRARY)
	if not visible:
		return
	if visible and to == StateManager.State.IN_GAME:
		state_manager.remove_state(StateManager.State.LIBRARY)

	# Load our library entries and add them to all games
	var library_entries: Dictionary = library_manager.get_installed()
	print("LIBRARY ENTRYES: ", library_entries)
	for entry in library_entries.values():
		for library_id in entry.keys():
			var item: LibraryItem = entry[library_id]
			# Build a poster for each library item
			var poster: TextureButton = poster_scene.instantiate()
			poster.layout = poster.LAYOUT_MODE.PORTRAIT
			#var img: Texture2D = item.texture
			#poster.texture_normal = img
			poster.text = item.name
			#poster.pressed.connect(_launch_store.bind(store))
			all_games_grid.add_child(poster)

	# Focus the first entry on state change
	for child in all_games_grid.get_children():
		child.grab_focus.call_deferred()
		break

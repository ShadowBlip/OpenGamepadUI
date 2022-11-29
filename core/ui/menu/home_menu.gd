extends Control

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var library_manager: LibraryManager = get_node("/root/Main/LibraryManager")
@onready var launch_manager: LaunchManager = get_node("/root/Main/LaunchManager")
@onready var container: HBoxContainer = $MarginContainer/ScrollContainer/HBoxContainer

var poster_scene: PackedScene = preload("res://core/ui/components/poster.tscn")
var state_changer_scene: PackedScene = preload("res://core/systems/state/state_changer.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)
	library_manager.library_reloaded.connect(_on_recent_apps_updated)
	launch_manager.recent_apps_changed.connect(_on_recent_apps_updated)

	# Grab the first button as focus
	_grab_focus()


func _on_recent_apps_updated():
	# Clear any old grid items
	for child in container.get_children():
		if child.name == "LibraryPoster":
			continue
		container.remove_child(child)
		child.queue_free()
	
	# Get the list of recent apps from LaunchManager
	var recent_apps: Array = launch_manager.get_recent_apps()
	
	# Get library items from the library manager
	# NOTE: Weirdly, Godot does not like pushing Resource objects to an array
	var items: Dictionary = {}
	for n in recent_apps:
		var name: String = n
		var library_item: LibraryItem = library_manager.get_app_by_name(name)
		if library_item == null:
			continue
		items[name] = library_item
	
	# Populate our grid with items
	_populate_grid(container, items.values())
	_grab_focus()


func _on_state_changed(from: int, to: int, _data: Dictionary):
	visible = state_manager.has_state(StateManager.State.HOME)
	if visible and to == StateManager.State.IN_GAME:
		state_manager.remove_state(StateManager.State.HOME)
	if to == StateManager.State.HOME:
		_grab_focus()


func _grab_focus():
	for child in container.get_children():
		child.grab_focus.call_deferred()
		break


# Populates the given grid with library items
func _populate_grid(grid: HBoxContainer, library_items: Array):
	var i: int = 0
	for entry in library_items:
		var item: LibraryItem = entry

		# Build a poster for each library item
		var poster: TextureButton = poster_scene.instantiate()
		poster.library_item = item
		if i == 0:
			poster.layout = poster.LAYOUT_MODE.LANDSCAPE
		else:
			poster.layout = poster.LAYOUT_MODE.PORTRAIT
		poster.text = item.name

		# TODO: Get texture from somewhere
		#var img: Texture2D = item.texture
		#poster.texture_normal = img

		# Build a launcher from the library item
		var state_changer: StateChanger = state_changer_scene.instantiate()
		state_changer.signal_name = "button_up"
		state_changer.state = StateManager.State.GAME_LAUNCHER
		state_changer.action = StateChanger.Action.PUSH
		state_changer.data = {"item": item}
		poster.add_child(state_changer)

		# Add the poster to the grid
		grid.add_child(poster)
		i += 1

	# Move our Library Poster to the back
	var library_poster: Node = grid.get_node("LibraryPoster")
	grid.move_child(library_poster, -1)

extends Control

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var home_state := preload("res://assets/state/states/home.tres") as State
var launcher_state := preload("res://assets/state/states/game_launcher.tres") as State
var poster_scene := preload("res://core/ui/components/poster.tscn") as PackedScene

@onready var container: HBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MarginContainer/HBoxContainer
@onready var banner: TextureRect = $SelectedBanner
@onready var player: AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LibraryManager.library_reloaded.connect(_on_recent_apps_updated)
	LaunchManager.recent_apps_changed.connect(_on_recent_apps_updated)
	home_state.state_entered.connect(_on_state_entered)


func _on_state_entered(_from: State) -> void:
	_grab_focus()
	
	
func _on_recent_apps_updated():
	# Clear any old grid items
	for child in container.get_children():
		if child.name == "LibraryPoster":
			continue
		container.remove_child(child)
		child.queue_free()
	
	# Get the list of recent apps from LaunchManager
	var recent_apps: Array = LaunchManager.get_recent_apps()
	
	# Get library items from the library manager
	# NOTE: Weirdly, Godot does not like pushing Resource objects to an array
	var items: Dictionary = {}
	for n in recent_apps:
		var name: String = n
		var library_item: LibraryItem = LibraryManager.get_app_by_name(name)
		if library_item == null:
			continue
		items[name] = library_item
	
	# Populate our grid with items
	_populate_grid(container, items.values())
	_grab_focus()


func _grab_focus():
	for child in container.get_children():
		child.grab_focus.call_deferred()
		break


# Called when a poster is focused
func _on_poster_focused(item: LibraryItem):
	player.stop()
	player.play("fade_in")
	banner.texture = await BoxArtManager.get_boxart_or_placeholder(item, BoxArtProvider.LAYOUT.BANNER)


func _on_poster_boxart_loaded(texture: Texture2D, poster: TextureButton):
	poster.texture_normal = texture


# Populates the given grid with library items
func _populate_grid(grid: HBoxContainer, library_items: Array):
	var i: int = 0
	for entry in library_items:
		var item: LibraryItem = entry

		# Build a poster for each library item
		var poster := poster_scene.instantiate() as TextureButton
		poster.library_item = item
		if i == 0:
			poster.layout = poster.LAYOUT_MODE.LANDSCAPE
		else:
			poster.layout = poster.LAYOUT_MODE.PORTRAIT
		poster.text = item.name

		# Get the boxart for the item
		var layout = BoxArtProvider.LAYOUT.GRID_PORTRAIT
		if poster.layout == poster.LAYOUT_MODE.LANDSCAPE:
			layout = BoxArtProvider.LAYOUT.GRID_LANDSCAPE
		poster.texture_normal = await BoxArtManager.get_boxart_or_placeholder(item, layout)
		
		# Listen for focus events on the posters
		poster.focus_entered.connect(_on_poster_focused.bind(item))

		# Listen for button presses and pass the library item with the state
		var on_button_up := func():
			launcher_state.data = {"item": item}
			state_machine.push_state(launcher_state)
		poster.button_up.connect(on_button_up)

		# Add the poster to the grid
		grid.add_child(poster)
		i += 1

	# Move our Library Poster to the back
	var library_poster: Node = grid.get_node("LibraryPoster")
	grid.move_child(library_poster, -1)

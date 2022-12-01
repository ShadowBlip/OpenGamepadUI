extends Control

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var library_manager: LibraryManager = get_node("/root/Main/LibraryManager")
@onready var boxart_manager: BoxArtManager = get_node("/root/Main/BoxArtManager")
@onready var tab_container: TabContainer = $TabContainer
@onready var all_games_grid: HFlowContainer = $"TabContainer/All Games/MarginContainer/HFlowContainer"
@onready var installed_games_grid: HFlowContainer = $"TabContainer/Installed/MarginContainer/HFlowContainer"

var poster_scene: PackedScene = preload("res://core/ui/components/poster.tscn")
var state_changer_scene: PackedScene = preload("res://core/systems/state/state_changer.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)
	library_manager.library_reloaded.connect(_on_library_reloaded)
	visible = false


func _on_library_reloaded() -> void:
	# Clear our old library entries
	# TODO: Make this better
	for child in all_games_grid.get_children():
		all_games_grid.remove_child(child)
		child.queue_free()
	for child in installed_games_grid.get_children():
		all_games_grid.remove_child(child)
		child.queue_free()
	
	# Load our library entries and add them to all games
	# TODO: Handle launching from multiple providers
	var available: Dictionary = library_manager.get_available()
	_populate_grid(all_games_grid, available.values())

	var installed: Dictionary = library_manager.get_installed()
	_populate_grid(installed_games_grid, installed.values())


# Populates the given grid with library items
func _populate_grid(grid: HFlowContainer, library_items: Array):
	for i in library_items:
		var item: LibraryItem = i
		
		# Build a poster for each library item
		var poster: TextureButton = poster_scene.instantiate()
		poster.library_item = item # Do we need this?
		poster.layout = poster.LAYOUT_MODE.PORTRAIT
		poster.text = item.name
		
		# Get the box art for the library item
		poster.texture_normal = await boxart_manager.get_boxart_or_placeholder(
			item, 
			BoxArtManager.Layout.GRID_PORTRAIT, 
		)
		
		# Build a launcher from the library item
		var state_changer: StateChanger = state_changer_scene.instantiate()
		state_changer.signal_name = "button_up"
		state_changer.state = StateManager.State.GAME_LAUNCHER
		state_changer.action = StateChanger.Action.PUSH
		state_changer.data = {"item": item}
		poster.add_child(state_changer)
		
		# Add the poster to the grid
		grid.add_child(poster)


func _on_state_changed(from: StateManager.State, to: StateManager.State, _data: Dictionary) -> void:
	visible = state_manager.has_state(StateManager.State.LIBRARY)
	if not visible:
		return
	if visible and to == StateManager.State.IN_GAME:
		state_manager.remove_state(StateManager.State.LIBRARY)

	# Focus the first entry on state change
	_on_tab_container_tab_changed(tab_container.current_tab)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	var num_tabs: int = tab_container.get_tab_count()
	var next_tab: int = tab_container.current_tab
	if event.is_action_pressed("ogui_tab_right"):
		next_tab += 1
	if event.is_action_pressed("ogui_tab_left"):
		next_tab -= 1
	
	if next_tab < 0:
		next_tab = num_tabs - 1
	if next_tab + 1 > num_tabs:
		next_tab = 0
	tab_container.current_tab = next_tab


func _on_tab_container_tab_changed(tab: int) -> void:
	# Get the child container to grab focus
	var container: ScrollContainer = tab_container.get_child(tab)
	var grid: HFlowContainer = container.get_child(0).get_child(0)
	
	# Focus the first entry on tab change
	for child in grid.get_children():
		child.grab_focus.call_deferred()
		break

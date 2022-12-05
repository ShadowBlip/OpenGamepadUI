extends Control

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var library_manager: LibraryManager = get_node("/root/Main/LibraryManager")
@onready var boxart_manager: BoxArtManager = get_node("/root/Main/BoxArtManager")
@onready var global_search: SearchBar = get_tree().get_nodes_in_group("global_search_bar")[0]
@onready var tab_container: TabContainer = $TabContainer
@onready var all_games_grid: HFlowContainer = $"TabContainer/All Games/MarginContainer/HFlowContainer"
@onready var installed_games_grid: HFlowContainer = $"TabContainer/Installed/MarginContainer/HFlowContainer"

var poster_scene: PackedScene = preload("res://core/ui/components/poster.tscn")
var state_changer_scene: PackedScene = preload("res://core/systems/state/state_changer.tscn")
var _library := {}
var _current_selection := {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_manager.state_changed.connect(_on_state_changed)
	library_manager.library_reloaded.connect(_on_library_reloaded)
	global_search.search_submitted.connect(_on_search)
	visible = false


# Handle searches
func _on_search(text: String):
	if state_manager.current_state() != StateManager.State.LIBRARY:
		return
	text = text.to_lower()
	
	# If the text is empty, set all items to visible
	if text == "":
		for tab_num in _library:
			for item_name in _library[tab_num]:
				var item: Control = _library[tab_num][item_name]
				item.visible = true
		return
		
	# TODO: Fuzzy searching?
	for tab_num in _library:
		for item_name in _library[tab_num]:
			var item: Control = _library[tab_num][item_name]
			if (item_name as String).to_lower().contains(text):
				item.visible = true
				continue
			item.visible = false


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
	_populate_grid(all_games_grid, available.values(), 1)

	var installed: Dictionary = library_manager.get_installed()
	_populate_grid(installed_games_grid, installed.values(), 0)


# Populates the given grid with library items
func _populate_grid(grid: HFlowContainer, library_items: Array, tab_num: int):
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
		
		# Listen for focus changes to keep track of our current selection
		# between state changes.
		poster.focus_entered.connect(_on_focus_updated.bind(poster, tab_num))
		
		# Add the poster to the grid
		grid.add_child(poster)
		
		# Keep track of all the library items so we can search them.
		if not tab_num in _library:
			_library[tab_num] = {}
		_library[tab_num][item.name] = poster


func _on_focus_updated(poster: TextureButton, tab: int) -> void:
	_current_selection[tab] = poster


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
	
	# If we had a previous selection, grab focus on that.
	if tab in _current_selection:
		var poster: TextureButton = _current_selection[tab]
		if poster.visible:
			poster.grab_focus.call_deferred()
			return
		# If the selection is no longer visible, clear it from our current selection
		_current_selection.erase(tab)
	
	# Otherwise, focus the first entry on tab change
	for child in grid.get_children():
		if child.visible:
			child.grab_focus.call_deferred()
			break

extends Control


var BoxArtManager := load("res://core/global/boxart_manager.tres") as BoxArtManager
var LibraryManager := load("res://core/global/library_manager.tres") as LibraryManager
var InstallManager := preload("res://core/global/install_manager.tres")
var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var library_state := preload("res://assets/state/states/library.tres") as State
var launcher_state := preload("res://assets/state/states/game_launcher.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State
var card_scene := preload("res://core/ui/components/card.tscn") as PackedScene
var tween: Tween
var _library := {}
var _current_selection := {}

@export var tabs_state: TabContainerState

@onready var global_search: SearchBar = get_tree().get_first_node_in_group("global_search_bar")
@onready var tab_container: TabContainer = $%TabContainer
@onready var all_games_grid: HFlowContainer = $%AllGamesGrid
@onready var installed_games_grid: HFlowContainer = $%InstalledGrid


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tabs_state.tab_changed.connect(_on_tab_container_tab_changed)
	library_state.state_entered.connect(_on_state_entered)
	LibraryManager.library_reloaded.connect(_on_library_reloaded)
	LibraryManager.library_registered.connect(_on_library_registered)
	LibraryManager.library_unregistered.connect(_on_library_unregistered)
	InstallManager.install_queued.connect(_on_install_queued)
	InstallManager.install_completed.connect(_on_installed)
	InstallManager.uninstall_completed.connect(_on_uninstalled)
	if global_search != null:
		global_search.search_submitted.connect(_on_search)


func _on_state_entered(_from: State):
	# Focus the first entry on state change
	_on_tab_container_tab_changed(tab_container.current_tab)


func _on_library_unregistered(_library_id: String) -> void:
	_on_library_reloaded(false)


func _on_library_registered(_library: Library) -> void:
	if not LibraryManager.is_initialized():
		return
	_on_library_reloaded(false)


# Handle searches
func _on_search(text: String):
	if not state_machine.current_state() in [library_state, osk_state]:
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


func _on_library_reloaded(_first_load: bool) -> void:
	# Clear our old library entries
	# TODO: Make this better
	for child in all_games_grid.get_children():
		#all_games_grid.remove_child(child)
		if child is FocusGroup:
			continue
		child.queue_free()
	for child in installed_games_grid.get_children():
		#all_games_grid.remove_child(child)
		if child is FocusGroup:
			continue
		child.queue_free()
	
	# Load our library entries and add them to all games
	var available := LibraryManager.get_library_items()
	_populate_grid(all_games_grid, available, 1)

	var modifiers: Array[Callable] = [
		LibraryManager.filter_installed,
		LibraryManager.sort_by_name,
	]
	var installed := LibraryManager.get_library_items(modifiers)
	_populate_grid(installed_games_grid, installed, 0)


# Builds a home card from the given library item
func _build_card(item: LibraryItem) -> GameCard:
	# Build a poster for each library item
	var card := card_scene.instantiate() as GameCard
	await card.set_library_item(item)

	# Listen for button presses and pass the library item with the state
	var on_button_up := func():
		launcher_state.data = {"item": item}
		state_machine.push_state(launcher_state)
	card.button_up.connect(on_button_up)
	
	return card


# Populates the given grid with library items
func _populate_grid(grid: HFlowContainer, library_items: Array, tab_num: int):
	for i in library_items:
		var item: LibraryItem = i
		
		# Build a card for each library item
		var card := await _build_card(item)

		# Listen for focus changes to keep track of our current selection
		# between state changes.
		card.focus_entered.connect(_on_focus_updated.bind(card, tab_num))
		
		# Listen for library item removed events
		var on_removed := func():
			_library[tab_num].erase(item.name)
		item.removed_from_library.connect(on_removed)
		
		# Add the card to the grid
		grid.add_child(card)
		
		# Keep track of all the library items so we can search them.
		if not tab_num in _library:
			_library[tab_num] = {}
		_library[tab_num][item.name] = card


# When an install is queued, connect signals to show a progress bar on the library
# card.
func _on_install_queued(req: InstallManager.Request) -> void:
	for tab_num in _library.keys():
		if not req.item.name in _library[tab_num]:
			continue
		var card := _library[tab_num][req.item.name] as GameCard
		card.value = 0
		card.show_progress = true
		var on_progress := func(progress: float):
			card.value = progress * 100
		req.progressed.connect(on_progress)
		var on_completed := func(success: bool):
			card.show_progress = false
			req.progressed.disconnect(on_progress)
		req.completed.connect(on_completed, CONNECT_ONE_SHOT)


# When an app is installed, ensure a card exists for it in the installed tab
# TODO: Add new card in installed tab
func _on_installed(req: InstallManager.Request) -> void:
	pass


# When an app is uninstalled, ensure a card DOESN'T exist for it on the installed tab
func _on_uninstalled(req: InstallManager.Request) -> void:
	var tab_num := 0
	if not req.success:
		return
	if not tab_num in _library:
		return
	if not req.item.name in _library[tab_num]:
		return
	var card: Control = _library[tab_num][req.item.name]
	_library[tab_num].erase(req.item.name)
	if tab_num in _current_selection and _current_selection[tab_num] == card:
		_current_selection.erase(tab_num)
	card.queue_free()


# Called when a library card is focused
func _on_focus_updated(card: Control, tab: int) -> void:
	_current_selection[tab] = card
	
	# Get the scroll container for this card
	var scroll_container := tab_container.get_child(tab) as ScrollContainer
	if not scroll_container:
		return
	
	# Smoothly scroll to the card using a tween
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(scroll_container, "scroll_vertical", card.position.y - card.size.y/3, 0.25)


func _on_tab_container_tab_changed(tab: int) -> void:
	# Update the tab container current tab
	tab_container.current_tab = tab
	
	# Get the child container to grab focus
	var container: ScrollContainer = tab_container.get_child(tab)
	var grid: HFlowContainer = container.get_child(1).get_child(0)
	
	# If we had a previous selection, grab focus on that.
	if tab in _current_selection:
		if is_instance_valid(_current_selection[tab]):
			var card: Control = _current_selection[tab]
			if card.visible:
				card.grab_focus.call_deferred()
				return
		# If the selection is no longer valid, clear it from our current selection
		_current_selection.erase(tab)
	
	# Otherwise, focus the first entry on tab change
	for child in grid.get_children():
		if child is FocusGroup:
			child.grab_focus()
			break
		if not child is Control:
			continue
		if child.visible:
			child.grab_focus.call_deferred()
			break

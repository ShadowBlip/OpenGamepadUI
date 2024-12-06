extends Control

signal refresh_completed

var LaunchManager := preload("res://core/global/launch_manager.tres") as LaunchManager
var InstallManager := preload("res://core/global/install_manager.tres")
var BoxArtManager := load("res://core/global/boxart_manager.tres") as BoxArtManager
var LibraryManager := load("res://core/global/library_manager.tres") as LibraryManager
var state_machine := preload("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var popup_state_machine := preload("res://assets/state/state_machines/popup_state_machine.tres") as StateMachine
var home_state := preload("res://assets/state/states/home.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var launcher_state := preload("res://assets/state/states/game_launcher.tres") as State
var card_scene := preload("res://core/ui/components/card.tscn") as PackedScene

var card_nodes := {}
var refresh_requested := false
var refresh_in_progress := false
var recent_apps: Array
var tween: Tween
var logger := Log.get_logger("HomeMenu", Log.LEVEL.INFO)

@onready var container := $%CardContainer as HBoxContainer
@onready var banner := $%BannerTexture as TextureRect
@onready var library_banner := $%LibraryBanner as Control
@onready var player := $%AnimationPlayer as AnimationPlayer
@onready var scroll_container := $%ScrollContainer as ScrollContainer
@onready var library_deck := $%LibraryDeck as LibraryDeck
@onready var end_spacer := $%EndSpacer as Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to state entered/exited signals
	home_state.state_entered.connect(_on_state_entered)
	home_state.state_exited.connect(_on_state_exited)
	home_state.refreshed.connect(_on_state_refreshed)
	
	# Clear any example grid items
	for child in container.get_children():
		if child.name in ["LibraryDeck", "StartSpacer", "EndSpacer"]:
			continue
		child.queue_free()
	
	# Scroll on focus on the LibraryCard
	library_deck.focus_entered.connect(_scroll_to.bind(library_deck))
	
	# Listen for library changes
	LibraryManager.library_item_added.connect(_on_library_item_changed)
	LibraryManager.library_item_removed.connect(_on_library_item_changed)
	
	# Listen for recent app changes and queued installs
	recent_apps = LaunchManager.get_recent_apps()
	LaunchManager.recent_apps_changed.connect(queue_refresh)
	InstallManager.install_queued.connect(_on_install_queued)
	
	# Show the library banner when the library deck is focused
	var on_library_focused := func():
		player.stop()
		player.play("fade_in")
		library_banner.visible = true
	library_deck.focus_entered.connect(on_library_focused)
	
	# Queue a home menu refresh
	queue_refresh()


## Queues the home menu to be refreshed
func queue_refresh() -> void:
	refresh_requested = true
	refresh()


func refresh() -> void:
	# Don't process if no refresh is requested or one is in progress
	if not refresh_requested or refresh_in_progress:
		return
	refresh_requested = false
	refresh_in_progress = true
	await _update_recent_apps()
	refresh_in_progress = false
	refresh_completed.emit()
	refresh.call_deferred()


func _on_state_entered(_from: State) -> void:
	set_process_input(true)
	library_banner.visible = false
	_grab_focus()


func _on_state_exited(_to: State) -> void:
	set_process_input(false)


func _on_state_refreshed() -> void:
	_grab_focus()


# Push the main menu state when the back button is pressed
func _input(event: InputEvent) -> void:
	# Only handle back button released and when the guide button is not held
	if not event.is_action_released("ogui_east") or Input.is_action_pressed("ogui_guide"):
		return

	# Stop the event from propagating
	get_viewport().set_input_as_handled()

	# Push the main menu state when the back button is pressed
	popup_state_machine.push_state(main_menu_state)


# When an install is queued, connect signals to show a progress bar on the library
# card.
func _on_install_queued(req: InstallManager.Request) -> void:
	if not req.item.name in recent_apps:
		return
	# Find the card
	var node := container.find_child(req.item.name, false)
	if not node is GameCard:
		return
	var card := node as GameCard
	var item := LibraryManager.get_app_by_name(req.item.name)
	card.value = 0
	card.show_progress = true
	var on_progress := func(progress: float):
		card.value = progress * 100
	req.progressed.connect(on_progress)
	var on_completed := func(success: bool):
		card.show_progress = false
		req.progressed.disconnect(on_progress)
	req.completed.connect(on_completed, CONNECT_ONE_SHOT)


func _on_library_item_changed(item: LibraryItem) -> void:
	var update_deck := func():
		if not library_deck.timer.is_stopped():
			return
		_update_library_deck()
		library_deck.timer.start()
	update_deck.call_deferred()
	if not item.name in recent_apps:
		return
	logger.debug("Recent app changed: " + item.name)
	queue_refresh()


func _update_recent_apps() -> void:
	recent_apps = LaunchManager.get_recent_apps()

	# Get the list of recent apps from LaunchManager
	var items: Array[LibraryItem] = []
	for n in recent_apps:
		var name: String = n
		var library_item: LibraryItem = LibraryManager.get_app_by_name(name)
		if library_item == null:
			continue
		items.append(library_item)
		
	# Populate our grid with items
	await _repopulate_grid(container, items)
	if not is_instance_valid(get_viewport()):
		return

	# Update the textures of the library deck
	await _update_library_deck()

	# Re-grab focus if nothing is focused
	if get_viewport().gui_get_focus_owner() == null:
		if state_machine.current_state() == home_state:
			_grab_focus()


func _update_library_deck() -> void:
	var library_items := LibraryManager.get_library_items()
	if library_items.size() == 0:
		return
	randomize()
	var card1 := library_items[randi() % library_items.size()]
	var tex1 := await BoxArtManager.get_boxart_or_placeholder(card1, BoxArtProvider.LAYOUT.GRID_PORTRAIT)
	var card2 := library_items[randi() % library_items.size()]
	var tex2 := await BoxArtManager.get_boxart_or_placeholder(card2, BoxArtProvider.LAYOUT.GRID_PORTRAIT)
	var card3 := library_items[randi() % library_items.size()]
	var tex3 := await BoxArtManager.get_boxart_or_placeholder(card3, BoxArtProvider.LAYOUT.GRID_PORTRAIT)
	library_deck.set_texture(0, tex1)
	library_deck.set_texture(1, tex2)
	library_deck.set_texture(2, tex3)


func _grab_focus() -> void:
	for child in container.get_children():
		if child.name in ["StartSpacer", "EndSpacer"]:
			continue
		child.grab_focus.call_deferred()
		break


# Called when a card is focused
func _on_card_focused(item: LibraryItem, card: Control) -> void:
	player.stop()
	player.play("fade_in")
	banner.texture = await BoxArtManager.get_boxart_or_placeholder(item, BoxArtProvider.LAYOUT.BANNER)
	library_banner.visible = false

	# Don't scroll to the card if mouse or touch is being used
	var input_manager := get_tree().get_first_node_in_group("InputManager")
	if input_manager:
		if (input_manager as InputManager).current_touches > 0:
			return
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return

	_scroll_to(card)


func _scroll_to(node: Control) -> void:
	# Smoothly scroll to the card using a tween
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(scroll_container, "scroll_horizontal", node.position.x - node.size.x/2, 0.15)


func _on_poster_boxart_loaded(texture: Texture2D, poster: TextureButton) -> void:
	poster.texture_normal = texture


# Builds a home card from the given library item
func _build_card(item: LibraryItem) -> GameCard:
	# Build a poster for each library item
	var card := card_scene.instantiate() as GameCard
	await card.set_library_item(item)
	
	# Listen for focus events on the posters
	card.focus_entered.connect(_on_card_focused.bind(item, card))

	# Listen for button presses and pass the library item with the state
	var on_button_up := func():
		launcher_state.data = {"item": item}
		state_machine.push_state(launcher_state)
	card.button_up.connect(on_button_up)
	
	return card


# Populates the given grid with library items
func _repopulate_grid(grid: HBoxContainer, library_items: Array[LibraryItem]) -> void:
	logger.debug("Repopulating grid: " + grid.name)
	# Create an array of library item names
	var item_names := PackedStringArray()
	for item in library_items:
		item_names.append(item.name)
	
	# Clear any old grid items
	for card_name in card_nodes.keys():
		if card_name in item_names:
			continue
		if not is_instance_valid(card_nodes[card_name]):
			continue
		logger.debug("Game " + card_name + " no longer exists in library. Removing.")
		var card_to_remove := card_nodes[card_name] as Control
		card_to_remove.queue_free()
		card_nodes.erase(card_name)
	
	# Organize posters by recently played
	var i: int = 0
	for item in library_items:
		var card: Control
		
		# Build a card for each library item if one does not exist
		if item.name in card_nodes and is_instance_valid(card_nodes[item.name]):
			card = card_nodes[item.name]
		else:
			card = await _build_card(item) as Control
			card_nodes[item.name] = card
			
			# Add the poster to the grid
			grid.add_child(card)
		
		# Move the card into the correct position
		grid.move_child(card, i+1)
		i += 1

	# Move our Library Deck to the back
	grid.move_child(library_deck, -1)
	grid.move_child(end_spacer, -1)

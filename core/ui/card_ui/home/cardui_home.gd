extends Control

var LaunchManager := preload("res://core/global/launch_manager.tres") as LaunchManager
var InstallManager := preload("res://core/global/install_manager.tres")
var BoxArtManager := load("res://core/global/boxart_manager.tres") as BoxArtManager
var LibraryManager := load("res://core/global/library_manager.tres") as LibraryManager
var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var home_state := preload("res://assets/state/states/home.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var launcher_state := preload("res://assets/state/states/game_launcher.tres") as State
var card_scene := preload("res://core/ui/components/card.tscn") as PackedScene
var _initialized := false
var repopulating := false
var recent_apps: Array
var tween: Tween

@onready var container: HBoxContainer = $%CardContainer
@onready var banner: TextureRect = $%BannerTexture
@onready var player: AnimationPlayer = $%AnimationPlayer
@onready var scroll_container: ScrollContainer = $%ScrollContainer
@onready var library_deck: LibraryDeck = $%LibraryDeck
@onready var end_spacer := $%EndSpacer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Clear any example grid items
	for child in container.get_children():
		if child.name in ["LibraryDeck", "StartSpacer", "EndSpacer"]:
			continue
		child.queue_free()
	
	# Scroll on focus on the LibraryCard
	library_deck.focus_entered.connect(_scroll_to.bind(library_deck))
	
	LibraryManager.library_reloaded.connect(_on_library_reloaded)
	LibraryManager.library_item_added.connect(_on_library_item_added)
	LibraryManager.library_registered.connect(_on_library_registered)
	LibraryManager.library_unregistered.connect(_on_library_unregistered)
	home_state.state_entered.connect(_on_state_entered)
	home_state.state_exited.connect(_on_state_exited)
	recent_apps = LaunchManager.get_recent_apps()
	LaunchManager.recent_apps_changed.connect(_on_recent_apps_updated)
	InstallManager.install_queued.connect(_on_install_queued)


func _on_state_entered(from: State) -> void:
	set_process_input(true)
	if from == null and not _initialized:
		_initialized = true
		return
	_grab_focus()


func _on_state_exited(_to: State) -> void:
	set_process_input(false)


# Push the main menu state when the back button is pressed
func _input(event: InputEvent) -> void:
	# Only handle back button pressed and when the guide button is not held
	if not event.is_action_pressed("ogui_east") or Input.is_action_pressed("ogui_guide"):
		return

	# Stop the event from propagating
	get_viewport().set_input_as_handled()

	# Push the main menu state when the back button is pressed
	state_machine.push_state(main_menu_state)



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


func _on_library_reloaded(_first_load: bool) -> void:
	_on_recent_apps_updated()


func _on_library_registered(_library: Library) -> void:
	if not LibraryManager.is_initialized():
		return
	_on_recent_apps_updated()
	
	
func _on_library_unregistered(_library_id: String) -> void:
	_on_recent_apps_updated()

	
func _on_library_item_added(item: LibraryItem) -> void:
	if not LibraryManager.is_initialized():
		return
	if not item.name in recent_apps:
		return
	_on_recent_apps_updated()
	
	
func _on_recent_apps_updated() -> void:
	recent_apps = LaunchManager.get_recent_apps()
		
	# Get the list of recent apps from LaunchManager
	# NOTE: Weirdly, Godot does not like pushing Resource objects to an array
	var items: Dictionary = {}
	for n in recent_apps:
		var name: String = n
		var library_item: LibraryItem = LibraryManager.get_app_by_name(name)
		if library_item == null:
			continue
		items[name] = library_item
		
	# Populate our grid with items
	await _repopulate_grid(container, items.values())
	if not is_instance_valid(get_viewport()):
		return
	if get_viewport().gui_get_focus_owner() == null:
		_grab_focus()
	
	# Update the textures of the library deck
	_update_library_deck()


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
	if state_machine.current_state() != home_state:
		return
	player.stop()
	player.play("fade_in")
	banner.texture = await BoxArtManager.get_boxart_or_placeholder(item, BoxArtProvider.LAYOUT.BANNER)
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
func _build_card(item: LibraryItem, portrait: bool) -> GameCard:
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
func _repopulate_grid(grid: HBoxContainer, library_items: Array) -> void:
	if repopulating:
		return
	repopulating = true
	# Clear any old grid items
	for child in container.get_children():
		if child.name in ["LibraryDeck", "StartSpacer", "EndSpacer"]:
			continue
		container.remove_child(child)
		child.queue_free()
	
	# Organize posters by recently played
	var i: int = 0
	for entry in library_items:
		var item: LibraryItem = entry

		# Build a poster for each library item
		var poster := await _build_card(item, i > 0) as Control

		# Add the poster to the grid
		grid.add_child(poster)
		i += 1

	# Move our Library Deck to the back
	grid.move_child(library_deck, -1)
	grid.move_child(end_spacer, -1)
	repopulating = false

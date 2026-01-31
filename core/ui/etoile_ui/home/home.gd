extends Control

var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager
var library_manager := preload("res://core/global/library_manager.tres") as LibraryManager
var settings_manager := preload("res://core/global/settings_manager.tres") as SettingsManager

var game_tile_scene := load("res://core/ui/etoile_ui/components/game_tile.tscn") as PackedScene
var global_state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var state_machine := preload("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var state := preload("res://assets/state/states/home.tres") as State
var menu_state := preload("res://assets/state/states/menu.tres") as State
var game_details_state := preload("res://assets/state/states/game_launcher.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var library_tile_texture := preload("res://assets/images/library-tile.png") as Texture2D

var tween: Tween
var recent_apps: Array[String] = []
var original_tile_size: Vector2
var original_tile_unselected_size: Vector2
var transition_duration := 0.5

@onready var container := %CarouselContainer as CarouselContainer
@onready var collections := %CollectionsContainer as Control
@onready var details := %DetailsContainer as Control
@onready var library_tile := %LibraryTile as GameTile


func _ready() -> void:
	self.original_tile_size = container.selected_size
	self.original_tile_unselected_size = container.unselected_size
	container.child_selected.connect(_on_child_selected)
	library_tile.set_texture(library_tile_texture)
	state.state_entered.connect(_on_state_entered)
	state.state_exited.connect(_on_state_exited)
	state.refreshed.connect(_on_state_refreshed)
	await library_manager.library_loaded
	_update_recent_apps()
	var first_tile := container.get_child(0)
	if first_tile and first_tile is Control:
		(first_tile as Control).grab_focus.call_deferred()

	# Listen for library changes
	library_manager.library_item_added.connect(_on_library_item_changed)
	library_manager.library_item_removed.connect(_on_library_item_changed)


func _on_state_entered(_from: State) -> void:
	var selected_node := container.get_child(container.selected_child)
	if selected_node and selected_node is Control:
		(selected_node as Control).grab_focus.call_deferred()
	if tween:
		tween.kill()
	var top_margin_spacer := get_parent().get_node("TopMarginSpacer")
	collections.modulate = Color(1, 1, 1, 0)
	collections.visible = true
	details.modulate = Color(1, 1, 1, 0)
	details.visible = true
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(collections, "modulate", Color(1, 1, 1, 1), transition_duration)
	tween.parallel().tween_property(details, "modulate", Color(1, 1, 1, 1), transition_duration)
	tween.parallel().tween_property(container, "selected_size", original_tile_size, transition_duration)
	tween.parallel().tween_property(container, "unselected_size", original_tile_unselected_size, transition_duration)
	tween.parallel().tween_property(container, "text_modulate", Color(1, 1, 1, 1), transition_duration)
	tween.parallel().tween_property(top_margin_spacer, "custom_minimum_size", Vector2.ZERO, transition_duration)


func _on_state_exited(to: State) -> void:
	if to == game_details_state:
		_on_game_details_state_entered(to)


func _on_game_details_state_entered(_state: State) -> void:
	if tween:
		tween.kill()
	var top_margin_spacer := get_parent().get_node("TopMarginSpacer")
	var game_details_size := container.unselected_size / 2.0
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(collections, "modulate", Color(1, 1, 1, 0), transition_duration)
	tween.parallel().tween_property(details, "modulate", Color(1, 1, 1, 0), transition_duration)
	tween.parallel().tween_property(container, "selected_size", game_details_size, transition_duration)
	tween.parallel().tween_property(container, "unselected_size", game_details_size, transition_duration)
	tween.parallel().tween_property(container, "text_modulate", Color(1, 1, 1, 0), transition_duration / 4.0)
	tween.parallel().tween_property(top_margin_spacer, "custom_minimum_size", Vector2(0, 80), transition_duration)
	tween.tween_property(collections, "visible", false, 0.0)
	tween.tween_property(details, "visible", false, 0.0)


func _on_state_refreshed() -> void:
	var selected_node := container.get_child(container.selected_child)
	if selected_node and selected_node is Control:
		(selected_node as Control).grab_focus.call_deferred()


func _on_library_item_changed(_item: LibraryItem) -> void:
	_update_recent_apps()


func _update_recent_apps() -> void:
	recent_apps.assign(launch_manager.get_recent_apps())
	var items: Array[LibraryItem] = []
	for app_name in recent_apps:
		var library_item := library_manager.get_app_by_name(app_name)
		if library_item == null:
			continue
		items.append(library_item)
	_repopulate_strip(items)


func _repopulate_strip(apps: Array[LibraryItem]) -> void:
	# Find any existing library items
	var existing_apps := {}
	for child in container.get_children():
		if not child is GameTile:
			continue
		var tile := child as GameTile
		if not tile.library_item:
			continue
		existing_apps[tile.library_item.name] = tile.library_item

	# Add any new items
	for item in apps:
		if item.name in existing_apps:
			continue
		var tile := await _build_tile(item)
		container.add_child(tile)


func _build_tile(item: LibraryItem) -> GameTile:
	var tile := game_tile_scene.instantiate() as GameTile
	await tile.set_library_item(item)

	return tile


func _on_child_selected(node: Node) -> void:
	if not node:
		return
	if not node is GameTile:
		return
	var tile := node as GameTile
	if tile.is_library_tile:
		var details_tween := create_tween()
		details_tween.tween_property(details, "modulate", Color(1, 1, 1, 0), transition_duration / 2.0)
		return
	if not tile.library_item:
		return
	game_details_state.set_meta("library_item", tile.library_item)
	game_details_state.refreshed.emit()
	if details.modulate != Color(1, 1, 1, 1):
		var details_tween := create_tween()
		details_tween.tween_property(details, "modulate", Color(1, 1, 1, 1), transition_duration / 2.0)



func _launch_game(launch_item: LibraryLaunchItem) -> void:
	# Resume if the game is running already
	if launch_manager.is_running(launch_item.name):
		state_machine.set_state([in_game_state])
		return

	# If the app isn't installed, install it.
	if not launch_item.installed:
		#_on_install()
		return

	# Launch the game using launch manager
	launch_manager.launch(launch_item)


# Lookup the current launch provider for the library item
func _get_launch_item(library_item: LibraryItem) -> LibraryLaunchItem:
	var launch_item := library_item.launch_items[0] as LibraryLaunchItem
	var section := "game.{0}".format([library_item.name.to_lower()])
	var provider_id := settings_manager.get_value(section, "provider", "") as String
	if provider_id != "":
		var possible_launch_item := library_item.get_launch_item(provider_id)
		if possible_launch_item != null:
			launch_item = possible_launch_item

	return launch_item


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	var focused_node := get_viewport().gui_get_focus_owner()
	if focused_node and not self.is_ancestor_of(focused_node):
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ogui_north"):
		if state_machine.current_state() != state:
			return
		var selected_node := container.get_child(container.selected_child)
		if not selected_node:
			return
		if not selected_node is GameTile:
			return
		var selected_tile := selected_node as GameTile
		if selected_tile.is_library_tile:
			return
		state_machine.push_state(game_details_state)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_up"):
		if state_machine.current_state() != game_details_state:
			return
		state_machine.pop_state()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_released("ui_accept"):
		var selected_node := container.get_child(container.selected_child)
		if not selected_node:
			return
		if not selected_node is GameTile:
			return
		var selected_tile := selected_node as GameTile
		var library_item := selected_tile.library_item
		if not library_item:
			return
		var launch_item := _get_launch_item(library_item)
		_launch_game(launch_item)

extends Control

var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager
var library_manager := preload("res://core/global/library_manager.tres") as LibraryManager
var game_tile_scene := load("res://core/ui/etoile_ui/components/game_tile.tscn") as PackedScene
var state := preload("res://assets/state/states/home.tres") as State
var game_details_state := preload("res://assets/state/states/game_launcher.tres") as State
var library_tile_texture := preload("res://assets/images/library-tile.png") as Texture2D

var tween: Tween
var recent_apps: Array[String] = []
var cards: Array[GameCard] = []
var card_selected := 0
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
	await library_manager.library_loaded
	_update_recent_apps()


func _on_state_entered(from: State) -> void:
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
	for item in apps:
		var card := await _build_card(item)
		container.add_child(card)


func _build_card(item: LibraryItem) -> GameTile:
	var card := game_tile_scene.instantiate() as GameTile
	await card.set_library_item(item)

	return card


func _on_child_selected(node: Node) -> void:
	if not node:
		return
	if not node is GameTile:
		return
	var tile := node as GameTile
	if tile.is_library_tile:
		return
	if not tile.library_item:
		return
	game_details_state.set_meta("library_item", tile.library_item)
	game_details_state.refreshed.emit()

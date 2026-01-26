extends Control

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var menu_state_machine := preload("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var home_state := preload("res://assets/state/states/home.tres") as State
var boxart_manager := preload("res://core/global/boxart_manager.tres") as BoxArtManager

var default_banner := preload("res://assets/images/starfield.svg") as Texture2D
var _tween: Tween

@onready var home_menu := %Home
@onready var banner := %BannerTexture as TextureRect

func _ready() -> void:
	# Initialize the state machine with its initial state
	menu_state_machine.push_state(home_state)

	# Listen for changes to the selected game tile on the home menu to update the
	# banner texture
	var game_carousel := home_menu.get_node("%CarouselContainer") as CarouselContainer
	game_carousel.child_selected.connect(_on_tile_selected)


func _on_tile_selected(node: Node) -> void:
	if not node is GameTile:
		return
	var tile := node as GameTile
	var texture: Texture2D
	if tile.is_library_tile:
		texture = default_banner
	elif tile.library_item:
		texture = await boxart_manager.get_boxart(tile.library_item, BoxArtProvider.LAYOUT.BANNER)

	if not texture:
		texture = default_banner

	if _tween:
		_tween.kill()
	_tween = create_tween()
	banner.modulate = Color(1, 1, 1, 0)
	banner.texture = texture
	_tween.tween_property(banner, "modulate", Color(1, 1, 1, 0.5), 1.2)

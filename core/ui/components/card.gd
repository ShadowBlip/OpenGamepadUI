@tool
@icon("res://assets/editor-icons/card-clubs.svg")
extends Control
class_name GameCard

var BoxArtManager := load("res://core/global/boxart_manager.tres") as BoxArtManager

signal button_up
signal button_down
signal pressed
signal highlighted
signal unhighlighted

@export_category("Label")
@export var show_label := false:
	set(v):
		show_label = v
		if name_container:
			name_container.visible = v
@export var text := "Game Name":
	set(v):
		text = v
		if name_label:
			name_label.text = v
@export_category("ProgressBar")
@export var show_progress := false:
	set(v):
		show_progress = v
		if progress:
			progress.visible = v
@export var value: float = 50:
	set(v):
		value = v
		if progress:
			progress.value = v

var library_item: LibraryItem
var logger := Log.get_logger("GameCard")

@onready var texture := $%TextureRect
@onready var name_container := $%NameMargin
@onready var name_label := $%NameLabel
@onready var progress := $%ProgressBar as ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name_container.visible = show_label
	name_label.text = text
	progress.visible = show_progress
	progress.value = value
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	texture.mouse_entered.connect(_on_focus)
	texture.mouse_exited.connect(_on_unfocus)
	
	# Set shader parameters
	var texture_size := texture.texture.get_size() as Vector2
	var radius := texture_size.x / 7.5
	texture.material.set_shader_parameter("corner_radius", radius)
	
	var parent := get_parent()
	if parent and parent is Container:
		parent.queue_sort()


## Sets the texture on the given card and sets the shader params
func set_texture(new_texture: Texture2D) -> void:
	var texture_rect := get_node("TextureRect")
	var texture_size := new_texture.get_size()
	texture_rect.texture = new_texture

	# Update the corner radius based on the image size
	var radius := texture_size.x / 7.5
	texture_rect.material.set_shader_parameter("corner_radius", radius)


## Configures the card with the given library item.
func set_library_item(item: LibraryItem, free_on_remove: bool = true) -> void:
	# Set the name based on the library item
	name = item.name
	library_item = item
	
	# Get the boxart for the item
	var layout = BoxArtProvider.LAYOUT.GRID_PORTRAIT
	var card_texture: Texture2D = await BoxArtManager.get_boxart(item, layout)
	if not card_texture:
		card_texture = BoxArtManager.get_placeholder(layout)
		show_label = true
		text = item.name
	set_texture(card_texture)

	# Listen for library removal signals and free the card if removed
	if free_on_remove:
		var on_removed := func() -> void:
			logger.debug("Removing card: " + name)
			queue_free()
		item.removed_from_library.connect(on_removed, CONNECT_ONE_SHOT)


func _on_focus() -> void:
	highlighted.emit()


func _on_unfocus() -> void:
	unhighlighted.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.double_click:
			button_up.emit()
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()

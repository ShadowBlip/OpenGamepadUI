@tool
@icon("res://assets/editor-icons/card-clubs.svg")
extends Control
class_name GameCard

var boxart_manager := load("res://core/global/boxart_manager.tres") as BoxArtManager

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
var tapped_count := 0
var logger := Log.get_logger("GameCard")

@onready var texture := $%TextureRect
@onready var name_container := $%NameMargin
@onready var name_label := $%NameLabel
@onready var progress := $%ProgressBar as ProgressBar
@onready var tap_timer := $%TapTimer as Timer
@onready var shine_rect := $%ShineShader as ColorRect
@onready var god_rays_rect := $%GodRaysShader as ColorRect


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

	# Setup a timer callback to clear number of taps on the card
	var on_timeout := func():
		tapped_count = 0
	tap_timer.timeout.connect(on_timeout)

	var parent := get_parent()
	if parent and parent is Container:
		parent.queue_sort()


## Sets the texture on the given card and sets the shader params
func set_texture(new_texture: Texture2D) -> void:
	var texture_rect := get_node("%TextureRect")
	texture_rect.texture = new_texture


## Configures the card with the given library item.
func set_library_item(item: LibraryItem, free_on_remove: bool = true) -> void:
	# Set the name based on the library item
	name = item.name
	library_item = item
	
	# Get the boxart for the item
	var layout = BoxArtProvider.LAYOUT.GRID_PORTRAIT
	var card_texture: Texture2D = await boxart_manager.get_boxart(item, layout)
	if not card_texture:
		card_texture = boxart_manager.get_placeholder(layout)
		show_label = true
		text = item.name
	set_texture(card_texture)

	# Listen for library removal signals and free the card if removed
	if free_on_remove:
		var on_removed := func() -> void:
			logger.debug("Removing card: " + name)
			queue_free()
		item.removed_from_library.connect(on_removed, CONNECT_ONE_SHOT)
		item.hidden.connect(on_removed, CONNECT_ONE_SHOT)


func _on_focus() -> void:
	highlighted.emit()
	_shader_godrays_fade_in()
	_shader_shine_fade_in()


func _shader_godrays_fade_in() -> void:
	var tween := create_tween()
	var shader := god_rays_rect.material as ShaderMaterial
	var final_color := Color(0.961, 0.937, 1.0, 0.2)
	var start_color := Color(0.961, 0.937, 1.0, 0.0)
	shader.set_shader_parameter("color", start_color)
	god_rays_rect.visible = true
	var on_tween := func(value: Color):
		shader.set_shader_parameter("color", value)
	tween.tween_method(on_tween, start_color, final_color, 0.5)


func _shader_shine_fade_in() -> void:
	var tween := create_tween()
	var shader := shine_rect.material as ShaderMaterial
	var final_alpha := 0.02
	var start_alpha := 0.0
	shader.set_shader_parameter("Alpha", start_alpha)
	shine_rect.visible = true
	var on_tween := func(value: float):
		shader.set_shader_parameter("Alpha", value)
	tween.tween_method(on_tween, start_alpha, final_alpha, 0.8)


func _on_unfocus() -> void:
	unhighlighted.emit()
	_shader_godrays_fade_out()
	_shader_shine_fade_out()


func _shader_godrays_fade_out() -> void:
	var tween := create_tween()
	var shader := god_rays_rect.material as ShaderMaterial
	var start_color := Color(0.961, 0.937, 1.0, 0.2)
	var final_color := Color(0.961, 0.937, 1.0, 0.0)
	shader.set_shader_parameter("color", start_color)
	var on_tween := func(value: Color):
		shader.set_shader_parameter("color", value)
	tween.tween_method(on_tween, start_color, final_color, 0.5)
	tween.tween_property(god_rays_rect, "visible", false, 0.0)


func _shader_shine_fade_out() -> void:
	var tween := create_tween()
	var shader := shine_rect.material as ShaderMaterial
	var start_alpha := 0.02
	var final_alpha := 0.0
	shader.set_shader_parameter("Alpha", start_alpha)
	var on_tween := func(value: float):
		shader.set_shader_parameter("Alpha", value)
	tween.tween_method(on_tween, start_alpha, final_alpha, 0.1)
	tween.tween_property(shine_rect, "visible", false, 0.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.double_click:
			button_up.emit()
	if event is InputEventScreenTouch:
		if event.is_pressed():
			tapped_count += 1
			if tapped_count > 1:
				tapped_count = 0
				button_up.emit()
			else:
				tap_timer.start()
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()

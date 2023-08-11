@tool
@icon("res://assets/editor-icons/button.svg")
extends PanelContainer
class_name CardMappingButton

signal pressed
signal button_up
signal button_down

enum AXIS_TYPE {
	NONE,
	X_FULL,
	X_LEFT,
	X_RIGHT,
	Y_FULL,
	Y_UP,
	Y_DOWN,
}

var axis := AXIS_TYPE.NONE

@export_category("Button")
@export var disabled := false

@export_category("Label")
@export var text := "Button":
	set(v):
		text = v
		if label:
			label.text = v
@export var label_settings: LabelSettings:
	set(v):
		label_settings = v
		if label:
			label.label_settings = v
@export var horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER:
	set(v):
		horizontal_alignment = v
		if label:
			label.horizontal_alignment = v
@export var vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER:
	set(v):
		vertical_alignment = v
		if label:
			label.vertical_alignment = v
@export var autowrap_mode: TextServer.AutowrapMode:
	set(v):
		autowrap_mode = v
		if label:
			label.autowrap_mode = v
@export var uppercase := true:
	set(v):
		uppercase = v
		if label:
			label.uppercase = v

@export_category("Animation")
@export var highlight_speed := 0.1

@export_category("AudioSteamPlayer")
@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/glitch_004.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/select_002.ogg"

@export_category("Mouse")
@export var click_focuses := true

var tween: Tween
var focus_audio_stream = load(focus_audio)
var select_audio_stream = load(select_audio)
var mappings: Array[MappableEvent] = []

@onready var label := $%Label as Label
@onready var highlight := $%HighlightTexture as TextureRect
@onready var texture := $%ControllerTextureRect as ControllerTextureRect
@onready var direction_arrow := $%ArrowTextureRect as TextureRect
@onready var direction_arrow2 := $%ArrowTextureRect2 as TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Configure the label
	label.text = text
	label.label_settings = label_settings
	label.horizontal_alignment = horizontal_alignment
	label.vertical_alignment = vertical_alignment
	label.autowrap_mode = autowrap_mode
	label.uppercase = uppercase
	
	# Connect signals
	pressed.connect(_play_sound.bind(select_audio_stream))
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	mouse_entered.connect(_on_focus)
	mouse_exited.connect(_on_unfocus)
	theme_changed.connect(_on_theme_changed)
	_on_theme_changed()


## Configures the button for the given mappable event
func set_mapping(events: Array[MappableEvent]) -> void:
	if events.size() == 0:
		return
	set_icon(events[0])


## Configures the button for the given mappable event
func set_icon(event: MappableEvent) -> void:
	if not texture or not event:
		return
	if event is EvdevEvent:
		texture.path = ControllerMapper.get_joypad_path_from_event(event)


## Returns true if the given event has a controller icon
func has_controller_icon(event: MappableEvent) -> bool:
	if event is EvdevEvent:
		return ControllerMapper.get_joypad_path_from_event(event) != ""
	return false


## Configures the button for the given axis type.
func set_axis_type(type: AXIS_TYPE) -> void:
	axis = type
	match axis:
		AXIS_TYPE.NONE:
			direction_arrow.visible = false
			direction_arrow2.visible = false
		AXIS_TYPE.X_FULL:
			direction_arrow.visible = true
			direction_arrow.texture = load("res://assets/ui/icons/arrow-right-bold.svg")
			direction_arrow.flip_h = false
			direction_arrow2.visible = true
			direction_arrow2.texture = load("res://assets/ui/icons/arrow-right-bold.svg")
		AXIS_TYPE.X_LEFT:
			direction_arrow.visible = true
			direction_arrow.texture = load("res://assets/ui/icons/arrow-right-bold.svg")
			direction_arrow.flip_h = true
			direction_arrow2.visible = false
		AXIS_TYPE.X_RIGHT:
			direction_arrow.visible = true
			direction_arrow.texture = load("res://assets/ui/icons/arrow-right-bold.svg")
			direction_arrow.flip_h = false
			direction_arrow2.visible = false
		AXIS_TYPE.Y_FULL:
			direction_arrow.visible = true
			direction_arrow.texture = load("res://assets/ui/icons/arrow-up-bold.svg")
			direction_arrow.flip_v = false
			direction_arrow2.visible = true
			direction_arrow2.texture = load("res://assets/ui/icons/arrow-up-bold.svg")
		AXIS_TYPE.Y_UP:
			direction_arrow.visible = true
			direction_arrow.texture = load("res://assets/ui/icons/arrow-up-bold.svg")
			direction_arrow.flip_v = false
			direction_arrow2.visible = false
		AXIS_TYPE.Y_DOWN:
			direction_arrow.visible = true
			direction_arrow.texture = load("res://assets/ui/icons/arrow-up-bold.svg")
			direction_arrow.flip_v = true
			direction_arrow2.visible = false


func _on_theme_changed() -> void:
	# Configure the highlight texture from the theme
	var highlight_texture := get_theme_icon("highlight", "CardButton")
	if highlight_texture:
		highlight.texture = highlight_texture


func _on_focus() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(highlight, "visible", true, 0)
	tween.tween_property(highlight, "modulate", Color(1, 1, 1, 0), 0)
	tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), highlight_speed)
	_play_sound(focus_audio_stream)


func _on_unfocus() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), 0)
	tween.tween_property(highlight, "modulate", Color(1, 1, 1, 0), highlight_speed)
	tween.tween_property(highlight, "visible", false, 0)
	

func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and not click_focuses:
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
	if not event.is_action("ui_accept"):
		return
	if event.is_pressed():
		button_down.emit()
		pressed.emit()
	else:
		button_up.emit()

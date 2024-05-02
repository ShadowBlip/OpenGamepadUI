@tool
@icon("res://assets/editor-icons/button.svg")
extends PanelContainer
class_name CardMappingButton

signal pressed
signal button_up
signal button_down

@export_category("Button")
@export var disabled := false

@export_category("Label")
@export var text := "Button":
	set(v):
		text = v
		if target_label:
			target_label.text = v
@export var label_settings: LabelSettings:
	set(v):
		label_settings = v
		if target_label:
			target_label.label_settings = v
@export var horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER:
	set(v):
		horizontal_alignment = v
		if target_label:
			target_label.horizontal_alignment = v
@export var vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER:
	set(v):
		vertical_alignment = v
		if target_label:
			target_label.vertical_alignment = v
@export var autowrap_mode: TextServer.AutowrapMode:
	set(v):
		autowrap_mode = v
		if target_label:
			target_label.autowrap_mode = v
@export var uppercase := true:
	set(v):
		uppercase = v
		if target_label:
			target_label.uppercase = v

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
var mappings: Array[InputPlumberMapping] = []

@onready var source_label := $%SourceLabel as Label
@onready var target_label := $%TargetLabel as Label
@onready var highlight := $%HighlightTexture as TextureRect
@onready var texture := $%ControllerTextureRect as TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Configure the label
	target_label.text = text
	target_label.label_settings = label_settings
	target_label.horizontal_alignment = horizontal_alignment
	target_label.vertical_alignment = vertical_alignment
	target_label.autowrap_mode = autowrap_mode
	target_label.uppercase = uppercase
	
	# Connect signals
	pressed.connect(_play_sound.bind(select_audio_stream))
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	mouse_entered.connect(_on_focus)
	mouse_exited.connect(_on_unfocus)
	theme_changed.connect(_on_theme_changed)
	_on_theme_changed()


## Configures the button for the given source capability
func set_capability(capability: String) -> void:
	print("Setting capabilibuddy: " + capability)
	if capability == "":
		return
	if set_icon(capability) != OK:
		print("No icon found for capability. Setting text instead.")
		source_label.visible = true
		texture.visible = false
		source_label.text = capability
		return
	source_label.visible = false
	texture.visible = true


## Configures the button for the given mappable event
func set_icon(capability: String) -> int:
	if not texture or not capability:
		return ERR_DOES_NOT_EXIST
	#ControllerMapper.convert_joypad_path_from_type()
	#if event is EvdevEvent:
	#	texture.path = ControllerMapper.get_joypad_path_from_event(event)
	return ERR_DOES_NOT_EXIST


## Returns true if the given event has a controller icon
func has_controller_icon(event: InputPlumberMapping) -> bool:
	#if event is EvdevEvent:
	#	return ControllerMapper.get_joypad_path_from_event(event) != ""
	return false


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

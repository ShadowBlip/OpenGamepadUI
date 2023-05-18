@tool
@icon("res://assets/editor-icons/button.svg")
extends PanelContainer
class_name CardButton

signal pressed
signal button_up
signal button_down

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

@onready var label := $%Label as Label
@onready var highlight := $%HighlightTexture as TextureRect


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

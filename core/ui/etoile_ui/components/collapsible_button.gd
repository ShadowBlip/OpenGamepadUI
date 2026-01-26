@icon("res://assets/editor-icons/button.svg")
@tool
extends MarginContainer
class_name CollapsibleButton

signal pressed
signal button_up
signal player_button_up(metaname: String, dbus_path: String)
signal button_down
signal player_button_down(metaname: String, dbus_path: String)

@export var disabled := false
@export var click_focuses := false
@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		if not icon:
			return
		icon.texture = icon_texture
		icon.visible = icon_texture != null
@export var text: String:
	set(v):
		text = v
		if not label:
			return
		label.text = text
		label.visible = not text.is_empty()
@export var split_panel: bool:
	set(v):
		split_panel = v
		if not split_panel_container:
			return
		split_panel_container.visible = expandable and split_panel
		var style := panel_container.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if expandable and split_panel:
			style.corner_radius_bottom_right = 0
			style.corner_radius_top_right = 0
		else:
			style.corner_radius_bottom_right = 12
			style.corner_radius_top_right = 12
		panel_container.add_theme_stylebox_override("panel", style)
@export var expandable: bool:
	set(v):
		expandable = v
		if not expand_icon:
			return
		expand_icon.visible = expandable and not split_panel
		spacer.visible = expandable and not split_panel
@export var color: Color:
	set(v):
		color = v
		if not panel_container:
			return
		if not color:
			return
		var style := panel_container.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.bg_color = color
		panel_container.add_theme_stylebox_override("panel", style)
@export_category("AudioSteamPlayer")
@export_file("*.ogg") var focus_audio := "res://assets/audio/interface/536764__egomassive__toss.ogg"
@export_file("*.ogg") var select_audio := "res://assets/audio/interface/96127__bmaczero__contact1.ogg"

var tween: Tween
var original_color: Color
var focus_audio_stream := load(focus_audio) as AudioStream
var select_audio_stream := load(select_audio) as AudioStream

@onready var icon := %Icon as TextureRect
@onready var label := %Label as Label
@onready var expand_icon := %ExpandIcon as TextureRect
@onready var spacer := %Spacer as Control
@onready var panel_container := %PrimaryPanelContainer as PanelContainer
@onready var split_panel_container := %SplitPanelContainer as PanelContainer
@onready var split_expand_icon := %SplitExpandIcon as TextureRect


func _ready() -> void:
	icon_texture = icon_texture
	text = text
	split_panel = split_panel
	expandable = expandable
	color = color
	original_color = color

	if Engine.is_editor_hint():
		return

	# Connect signals
	pressed.connect(_play_sound.bind(select_audio_stream))
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	mouse_entered.connect(_on_focus)
	mouse_exited.connect(_on_unfocus)

func _on_focus() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "color", Color(1, 1, 1, 0.5), 0.5)
	_play_sound(focus_audio_stream)


func _on_unfocus() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "color", original_color, 0.5)


func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	var dbus_path := event.get_meta("dbus_path", "") as String
	if event is InputEventMouseButton and not click_focuses:
		if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
			return
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
	if not event.is_action("ui_accept"):
		return
	if event.is_pressed():
		button_down.emit()
		player_button_down.emit("dbus_path", dbus_path)
		pressed.emit()
	else:
		button_up.emit()
		player_button_up.emit("dbus_path", dbus_path)

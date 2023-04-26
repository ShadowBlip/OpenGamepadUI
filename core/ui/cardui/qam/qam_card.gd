@tool
extends Container

signal pressed
signal button_up
signal button_down
signal toggled(pressed: bool)

@export_category("Card")
@export var title := "Section"
@export var is_toggled := false

@export_category("Animation")
@export var highlight_speed := 0.1

@export_category("AudioSteamPlayer")
@export_file("*.ogg") var focus_audio = "res://assets/audio/interface/glitch_004.ogg"
@export_file("*.ogg") var select_audio = "res://assets/audio/interface/select_002.ogg"

@onready var label := $%SectionLabel
@onready var separator := $%HSeparator
@onready var content_container := $%ContentContainer
@onready var inside_panel := $%InsidePanel
@onready var margin_container := $%MarginContainer
@onready var highlight := $%HighlightTexture as TextureRect

var tween: Tween
var highlight_tween: Tween
var focus_group: FocusGroup
var focus_audio_stream = load(focus_audio)
var select_audio_stream = load(select_audio)
var logger := Log.get_logger("QAMCard", Log.LEVEL.DEBUG)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	pressed.connect(_on_pressed)
	label.text = title
	
	# Do nothing if running in the editor
	if Engine.is_editor_hint():
		return
	
	# Resize any children that are Control nodes
	for child in content_container.get_children():
		# If the node is a control, resize it based on its children
		if child.get_class() == "Control":
			for c in child.get_children():
				if not c is Control:
					continue
				(child as Control).custom_minimum_size += c.size
	
	# Try and find a FocusGroup in the content to focus
	focus_group = _find_child_focus_group(content_container.get_children())


# Recursively searches for FocusGroups in the given array of nodes. Returns the
# first one it finds
func _find_child_focus_group(nodes: Array[Node]) -> FocusGroup:
	if nodes.size() == 0:
		logger.debug("No children to check for FocusGroup.")
		return null

	for node in nodes:
		var focusable: Node
		logger.debug("Considering node: " + node.name)
		# Check if node is a child FocusGroup
		if node is FocusGroup:
			return node
		# Otherwise try and recursively find a child that can be focused
		logger.debug("Node: " + node.name + " is not a FocusGroup. Checking its children.")
		focusable = _find_child_focus_group(node.get_children())
		if focusable:
			return focusable
	logger.debug("No child FocusGroup was found.")
	return null


func _on_focus() -> void:
	_highlight()
	
	# If the card gets focused, and its already expanded, that means we've
	# the user has focused outside the card, and we should shrink to hide the
	# content
	if is_toggled:
		_on_pressed()


func _on_unfocus() -> void:
	# If a child focus group is focused, don't do anything. That means that
	if not focus_group:
		logger.warn("No focus group defined!")
		return

	# a child node is focused and we want the card to remain "selected"
	if focus_group.is_in_focus_stack():
		return
	
	_unhighlight()


func _highlight() -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = get_tree().create_tween()
	highlight_tween.tween_property(highlight, "visible", true, 0)
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 0), 0)
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), highlight_speed)
	_play_sound(focus_audio_stream)
	
	
func _unhighlight() -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = get_tree().create_tween()
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 1), 0)
	highlight_tween.tween_property(highlight, "modulate", Color(1, 1, 1, 0), highlight_speed)
	highlight_tween.tween_property(highlight, "visible", false, 0)


func _on_pressed() -> void:
	is_toggled = !is_toggled
	if is_toggled:
		_grow()
	else:
		_shrink()
	
	toggled.emit(is_toggled)


func _grow() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "custom_minimum_size", Vector2(0, size.y + content_container.size.y), 0.2)
	tween.tween_property(inside_panel, "visible", true, 0)
	tween.tween_property(content_container, "visible", true, 0)
	tween.tween_property(separator, "visible", true, 0)
	tween.tween_property(inside_panel, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(content_container, "modulate", Color(1, 1, 1, 1), 0.2)
	
	# After growing finishes, grab focus on the child focus group
	var on_grown := func():
		if not focus_group:
			logger.warn("No focus group to grab!")
			return
		focus_group.grab_focus()
		
	tween.tween_callback(on_grown)
	
	
func _shrink() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(content_container, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(inside_panel, "modulate", Color(1, 1, 1, 0), 0.1)
	tween.tween_property(separator, "visible", false, 0)
	tween.tween_property(inside_panel, "visible", false, 0)
	tween.tween_property(content_container, "visible", false, 0)
	tween.tween_property(self, "custom_minimum_size", Vector2(0, 0), 0.2)
	tween.tween_callback(grab_focus)


func _play_sound(stream: AudioStream) -> void:
	var audio_player: AudioStreamPlayer = $AudioStreamPlayer
	audio_player.stream = stream
	audio_player.play()


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()

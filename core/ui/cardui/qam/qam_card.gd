@tool
extends Container

signal pressed
signal button_up
signal button_down
signal toggled(pressed: bool)

@export var title := "Section"
@export var is_toggled := false

@onready var label := $%SectionLabel
@onready var separator := $%HSeparator
@onready var content_container := $%ContentContainer
@onready var margin_container := $%MarginContainer

var tween: Tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#focus_entered.connect(_play_sound.bind(_focus_audio_stream))
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	grab_focus.call_deferred() # TMP
	pressed.connect(_on_pressed)
	label.text = title
	
	# Do nothing if running in the editor
	if Engine.is_editor_hint():
		return
	
	# Move children under the content container
	for child in get_children():
		if child == margin_container:
			continue
		child.reparent(content_container)
		
		# If the node is a control, resize it based on its children
		if child.get_class() == "Control":
			for c in child.get_children():
				(child as Control).custom_minimum_size += c.size


func _on_focus() -> void:
	var style := get("theme_override_styles/panel") as StyleBoxFlat
	style.border_width_left = 4
	style.border_width_bottom = 4
	style.border_width_top = 4
	style.border_width_right = 4


func _on_unfocus() -> void:
	for child in content_container.get_children():
		if not child is Control:
			continue
		if child.has_focus():
			return
	
	var style := get("theme_override_styles/panel") as StyleBoxFlat
	style.border_width_left = 0
	style.border_width_bottom = 0
	style.border_width_top = 0
	style.border_width_right = 0
	#if is_toggled:
	#	_on_pressed()


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
#	var focus_node: Control
#	for child in content_container.get_children():
#		if not child is Control:
#			continue
#		focus_node = child
#		break
#	var on_grown := func():
#		if not focus_node:
#			return
#		focus_node.grab_focus.call_deferred()
	tween.tween_property(self, "custom_minimum_size", Vector2(0, size.y + content_container.size.y), 0.2)
	tween.tween_property(content_container, "visible", true, 0)
	tween.tween_property(separator, "visible", true, 0)
	tween.tween_property(content_container, "modulate", Color(1, 1, 1, 1), 0.2)
	#tween.tween_callback(on_grown)
	
	
func _shrink() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(content_container, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(separator, "visible", false, 0)
	tween.tween_property(content_container, "visible", false, 0)
	tween.tween_property(self, "custom_minimum_size", Vector2(0, 0), 0.2)
	tween.tween_callback(grab_focus)


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()

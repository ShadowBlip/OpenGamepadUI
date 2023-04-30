@tool
extends Effect
class_name GrowerEffect

@export_category("Targets")
@export var target: Control = get_parent()
@export var content_container: Control
@export var inside_panel: Control
@export var separator: Control
@export_category("Animation")
@export var highlight_speed := 0.1
@export_category("Focus")
@export var focus_group: FocusGroup

var tween: Tween


func _on_signal() -> void:
	_grow()


func _grow() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(target, "custom_minimum_size", Vector2(0, target.size.y + content_container.size.y), 0.2)
	if inside_panel:
		tween.tween_property(inside_panel, "visible", true, 0)
	if content_container:
		tween.tween_property(content_container, "visible", true, 0)
	if separator:
		tween.tween_property(separator, "visible", true, 0)
	if inside_panel:
		tween.tween_property(inside_panel, "modulate", Color(1, 1, 1, 1), 0.1)
	if content_container:
		tween.tween_property(content_container, "modulate", Color(1, 1, 1, 1), 0.2)
	
	# After growing finishes, grab focus on the child focus group
	var on_grown := func():
		if not focus_group:
			return
		focus_group.grab_focus()
		
	tween.tween_callback(on_grown)

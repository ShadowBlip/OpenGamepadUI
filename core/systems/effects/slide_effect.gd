@tool
extends Effect
class_name SlideEffect

signal slide_out_started
signal slide_out_finished

@export_category("Target")
## The target node to slide
@export var target: Control = get_parent()
@export_category("Animation")
## Time in seconds to complete the slide effect
@export var slide_speed := 0.1
## Margin in pixels to start from
@export var margin := 20
## Direction to slide into view from.
@export_enum("left", "right", "up", "down") var direction := "right"

var tween: Tween
var slide_out_signal: String


func _ready() -> void:
	notify_property_list_changed()
	if slide_out_signal != "":
		get_parent().connect(slide_out_signal, _on_out_signal)


func _on_signal():
	slide_in()


func _on_out_signal():
	slide_out()


func slide_in() -> void:
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()
	target.visible = true
	target.set_position.call_deferred(_get_target_pos(direction))
	tween = tree.create_tween()
	tween.tween_property(target, "position", Vector2.ZERO, slide_speed)
	var on_finished := func():
		effect_finished.emit()
	tween.tween_callback(on_finished)
	effect_started.emit()


func slide_out() -> void:
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()

	var target_pos := _get_target_pos(direction)
	
	tween = tree.create_tween()
	tween.tween_property(target, "position", target_pos, slide_speed)
	tween.tween_property(target, "visible", false, 0)
	var on_finished := func():
		slide_out_finished.emit()
	tween.tween_callback(on_finished)
	slide_out_started.emit()


func _get_target_pos(dir: String) -> Vector2:
	var directions := {
		"left": Vector2(-target.size.x - margin, 0),
		"right": Vector2(target.size.x + margin, 0),
		"up": Vector2(0, -target.size.y - margin),
		"down": Vector2(0, target.size.y + margin),
	}
	
	return directions[dir] as Vector2


# Customize editor properties that we expose. Here we dynamically look up
# the parent node's signals so we can display them in a list.
func _get_property_list():
	# By default, `on_signal` is not visible in the editor.
	var property_usage := PROPERTY_USAGE_NO_EDITOR

	var parent_signals := []
	if get_parent() != null:
		property_usage = PROPERTY_USAGE_DEFAULT
		for sig in get_parent().get_signal_list():
			parent_signals.push_back(sig["name"])

	var properties := []
	properties.append(
			{
				"name": "on_signal",
				"type": TYPE_STRING,
				"usage": property_usage,  # See above assignment.
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(parent_signals)
			}
	)
	properties.append(
			{
				"name": "slide_out_signal",
				"type": TYPE_STRING,
				"usage": property_usage,  # See above assignment.
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(parent_signals)
			}
	)

	return properties

@tool
extends Effect
class_name FadeEffect

## Emitted when the effect finishes
signal fade_out_finished

@export_category("Target")
## The target node to fade the opacity in/out
@export var target: Control = get_parent()
@export_category("Animation")
## Fade speed in seconds
@export var fade_speed := 0.1

var tween: Tween

## Signal to connect to to trigger a fade out
var fade_out_signal: String


func _ready() -> void:
	notify_property_list_changed()
	if fade_out_signal != "":
		get_parent().connect(fade_out_signal, _on_out_signal)


func _on_signal():
	fade_in()


func _on_out_signal():
	fade_out()


func fade_in() -> void:
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()
	target.visible = true
	target.modulate = Color(1, 1, 1, 0)
	tween = tree.create_tween()
	tween.tween_property(target, "modulate", Color(1, 1, 1, 1), fade_speed)
	var on_finished := func():
		effect_finished.emit()
	tween.tween_callback(on_finished)


func fade_out() -> void:
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()
	target.modulate = Color(1, 1, 1, 1)
	tween = tree.create_tween()
	tween.tween_property(target, "modulate", Color(1, 1, 1, 0), fade_speed)
	tween.tween_property(target, "visible", false, 0)
	var on_finished := func():
		fade_out_finished.emit()
	tween.tween_callback(on_finished)


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
				"name": "fade_out_signal",
				"type": TYPE_STRING,
				"usage": property_usage,  # See above assignment.
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(parent_signals)
			}
	)

	return properties

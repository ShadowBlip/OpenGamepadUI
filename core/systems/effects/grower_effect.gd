@tool
extends Effect
class_name GrowerEffect

## Grow the given target's custom minimum size to the size of the given content
##
## Optionally an inside panel and separator can be specified to make them visible
## when the parent fully grows.

signal shrink_finished

@export_category("Targets")
## The target node to grow. This will animate the minimum custom size of this node
## to be the size of the content container.
@export var target: Control = get_parent()
## Content that the target node will grow to match the size.
@export var content_container: Control
## Optional inside panel to toggle visibility after growing.
@export var inside_panel: Control
## Optional separator to toggle visibility after growing.
@export var separator: Control
@export_category("Animation")
## The speed of the grow animation in seconds.
@export var grow_speed := 0.2

var tween: Tween
var shrink_signal: String


func _ready() -> void:
	notify_property_list_changed()
	if shrink_signal != "":
		get_parent().connect(shrink_signal, _on_shrink_signal)

	# Do nothing if running in the editor
	if Engine.is_editor_hint():
		return


func _on_signal() -> void:
	grow()


func _on_shrink_signal():
	shrink()


func grow() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	
	var content_size := 0
	if content_container:
		content_size = content_container.size.y

	var target_size := target.size.y + content_size
	content_container.visible = false
	tween.tween_property(target, "custom_minimum_size", Vector2(0, target_size), grow_speed)
	if inside_panel:
		tween.tween_property(inside_panel, "visible", true, 0)
	if content_container:
		tween.tween_property(content_container, "visible", true, 0)
	if separator:
		tween.tween_property(separator, "visible", true, 0)
	if inside_panel:
		tween.tween_property(inside_panel, "modulate", Color(1, 1, 1, 1), 0.1)
	if content_container:
		tween.tween_property(content_container, "modulate", Color(1, 1, 1, 1), grow_speed)
	
	var on_finished := func():
		effect_finished.emit()
	tween.tween_callback(on_finished)


func shrink() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(content_container, "modulate", Color(1, 1, 1, 0), grow_speed)
	if inside_panel:
		tween.tween_property(inside_panel, "modulate", Color(1, 1, 1, 0), 0.1)
	if separator:
		tween.tween_property(separator, "visible", false, 0)
	if inside_panel:
		tween.tween_property(inside_panel, "visible", false, 0)
	if content_container:
		tween.tween_property(content_container, "visible", false, 0)
	tween.tween_property(target, "custom_minimum_size", Vector2(0, 0), grow_speed)
	var on_finished := func():
		shrink_finished.emit()
	tween.tween_callback(on_finished)


## Recursively calculates the total height of all children for the given node
func _calculate_size(control: Control) -> int:
	var size := 0
	for child in control.get_children():
		if not child is Control:
			continue
		size += _calculate_size(child)

	if not control is Container:
		print("Adding node size for ", control.name, ": ", control.size.y)
		size += control.size.y

	return size


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
				"name": "shrink_signal",
				"type": TYPE_STRING,
				"usage": property_usage,  # See above assignment.
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(parent_signals)
			}
	)

	return properties


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not target:
		warnings.append("Target node to grow must be selected")
	if not content_container:
		warnings.append("Content container must be selected to determine size to grow to!")
		
	return warnings

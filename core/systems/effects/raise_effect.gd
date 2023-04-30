@tool
extends Effect
class_name RaiseEffect

@export_category("Targets")
@export var target: Control
@export var shadow: PanelContainer
@export_category("Animation")
@export var raise_speed := 0.2
@export var raise_to_position := Vector2(0, -40)
@export var scale_on_raised := Vector2(1.01, 1.01)
@export var shadow_size_on_raised := 20

var tween: Tween
var lower_signal: String
var orig_shadow_size := 0


func _ready() -> void:
	if shadow:
		var panel_style = shadow.get("theme_override_styles/panel")
		orig_shadow_size = panel_style.get("shadow_size")
	notify_property_list_changed()
	if lower_signal != "":
		get_parent().connect(lower_signal, _on_lower_signal)


func _on_signal() -> void:
	raise()


func _on_lower_signal():
	lower()


func raise() -> void:
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()
	tween = tree.create_tween()
	tween.tween_property(target, "scale", scale_on_raised, raise_speed)
	tween.parallel().tween_property(target, "position", raise_to_position, raise_speed)
	if shadow:
		tween.parallel().tween_property(shadow, "theme_override_styles/panel:shadow_size", shadow_size_on_raised, raise_speed)


func lower() -> void:
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()
	tween = tree.create_tween()
	tween.tween_property(target, "scale", Vector2(1, 1), raise_speed)
	tween.parallel().tween_property(target, "position", Vector2(0, 0), raise_speed)
	if shadow:
		tween.parallel().tween_property(shadow, "theme_override_styles/panel:shadow_size", orig_shadow_size, raise_speed)


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
				"name": "lower_signal",
				"type": TYPE_STRING,
				"usage": property_usage,  # See above assignment.
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(parent_signals)
			}
	)

	return properties

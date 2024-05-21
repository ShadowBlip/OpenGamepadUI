extends Effect
class_name SmoothScrollEffect

var tween: Tween

@export_category("Target")
@export var target: ScrollContainer
@export_category("Animation")
@export_enum("both", "vertical", "horizontal") var scroll_type = "both"
@export var scroll_speed := 0.25


func _ready() -> void:
	pass


func _on_signal() -> void:
	pass


func scroll(to_node: Control) -> void:
	var tree := get_tree()
	if not tree or not target:
		return
	if tween:
		tween.kill()
	tween = tree.create_tween()
	var on_finished := func():
		effect_finished.emit()
	if scroll_type == "vertical":
		tween.tween_property(target, "scroll_vertical", to_node.position.y - to_node.size.y/3, scroll_speed)
		tween.tween_callback(on_finished)
		return
	if scroll_type == "horizontal":
		tween.tween_property(target, "scroll_horizontal", to_node.position.x - to_node.size.x/3, scroll_speed)
		tween.tween_callback(on_finished)
		return

	tween.parallel().tween_property(target, "scroll_vertical", to_node.position.y - to_node.size.y/3, scroll_speed)
	tween.parallel().tween_property(target, "scroll_horizontal", to_node.position.x - to_node.size.x/3, scroll_speed)
	tween.tween_callback(on_finished)

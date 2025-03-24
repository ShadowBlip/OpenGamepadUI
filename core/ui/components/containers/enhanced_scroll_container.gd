@tool
extends ScrollContainer
class_name EnhancedScrollContainer

@export var maximum_size: Vector2i:
	set(v):
		maximum_size = v
		_on_sort_children()

func _ready() -> void:
	sort_children.connect(_on_sort_children)


func _on_sort_children() -> void:
	if get_child_count() == 0:
		return
	var child: Control
	for c in get_children():
		if not c is Control:
			continue
		child = c
		break
	if not child:
		return

	custom_minimum_size.x = min(child.size.x, maximum_size.x)
	custom_minimum_size.y = min(child.size.y, maximum_size.y)

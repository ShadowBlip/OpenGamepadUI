@icon("res://assets/editor-icons/move.svg")
extends Node
class_name ScrollerJoystick

## Scroll a [ScrollContainer] using the right analog stick
##
## Add as a child node to a [ScrollContainer] to allow controlling the scroll
## position using the right analog stick.

@export var scroll_speed := 600
@export var dead_zone := Vector2(0.2, 0.2)

@onready var parent: ScrollContainer = get_parent()

var direction := Vector2.ZERO
var remainder := Vector2.ZERO


func _process(delta: float) -> void:
	if not parent.is_visible_in_tree():
		return
	if abs(direction.x) < dead_zone.x and abs(direction.y) < dead_zone.y:
		return
	var current_pos := Vector2(parent.scroll_horizontal, parent.scroll_vertical)
	var target_pos := current_pos + (direction * scroll_speed * delta)
	
	# Keep track of the fractions leftover
	var x: int = floor(target_pos.x)
	var y: int = floor(target_pos.y)
	var fraction := Vector2(target_pos.x - x, target_pos.y - y)
	
	# Keep track of fractional numbers across frames
	remainder += fraction
	if remainder.x > 1:
		target_pos.x += 1
		remainder.x -= 1
	if remainder.y > 1:
		target_pos.y += 1
		remainder.y -= 1
	
	parent.scroll_horizontal = target_pos.x
	parent.scroll_vertical = target_pos.y
	print(target_pos)


func _input(event: InputEvent) -> void:
	if not event is InputEventJoypadMotion:
		return
	var joy_event := event as InputEventJoypadMotion
	if not joy_event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
		return
	if not parent.is_visible_in_tree():
		return

	if joy_event.axis == JOY_AXIS_RIGHT_X:
		direction.x = joy_event.axis_value
		return
	direction.y = joy_event.axis_value

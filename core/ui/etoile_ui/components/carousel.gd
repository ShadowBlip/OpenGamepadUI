@tool
extends Container
class_name CarouselContainer

signal child_selected(node: Node)

## Text to display next to selected node
@export var text: String:
	set(v):
		text = v
		if not label:
			return
		label.text = v
@export var text_settings: LabelSettings
@export var text_modulate := Color(1, 1, 1, 1):
	set(v):
		text_modulate = v
		if not label:
			return
		label.modulate = v
## Spacing between nodes
@export var spacing: int = 10:
	set(v):
		spacing = v
		if self.get_child_count() > 0:
			_on_sort_children()
## Currently selected node
@export var selected_child: int = 0:
	set(v):
		selected_child = v
		if self.get_child_count() > 0:
			_on_child_selected()
			_on_sort_children()
## Size of the selected node
@export var selected_size: Vector2 = Vector2(234, 234):
	set(v):
		selected_size = v
		if self.get_child_count() > 0:
			_on_sort_children()
## Size of unselected nodes
@export var unselected_size: Vector2 = Vector2(166, 166):
	set(v):
		unselected_size = v
		if self.get_child_count() > 0:
			_on_sort_children()
## Animation duration
@export var duration: float = 0.5

@onready var label := Label.new()

var _grow_tween: Tween
var logger := Log.get_logger("Carousel", Log.LEVEL.DEBUG)

# NOTE: When the user is at the beginning of the list and goes left, the last item
# in the list should be inserted in the front and popped from the back

func _ready() -> void:
	label.text = text
	label.label_settings = text_settings
	add_child(label, false, Node.INTERNAL_MODE_BACK)
	sort_children.connect(_on_sort_children)
	child_entered_tree.connect(_on_child_entered_tree)
	if self.get_child_count() == 1:
		return
	_on_sort_children()


func _on_sort_children() -> void:
	# Position the label node
	self.label.position = Vector2(selected_size.x + spacing, unselected_size.y + spacing)

	# Find the selected child node
	var selected := get_child(selected_child)
	if not selected:
		return

	# Increase the size and move the selected child
	self._grow_tween = selected.create_tween()
	self._grow_tween.set_ease(Tween.EASE_IN_OUT)
	self._grow_tween.tween_property(selected, "position", Vector2.ZERO, duration)
	self._grow_tween.tween_property(selected, "size", selected_size, duration / 3.0)

	# Calculate child positions BEHIND selected node
	var target_position := 0.0
	var i := self.selected_child - 1
	while i >= 0:
		var child := self.get_child(i)
		if child == label:
			i -= 1
			continue
		if not child is Control:
			continue
		target_position -= spacing + unselected_size.x
		#(child as Control).position.x = target_position
		var tween := child.create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(child, "position", Vector2(target_position, 0), duration)
		var size_tween := child.create_tween()
		size_tween.tween_property(child, "size", unselected_size, duration)
		i -= 1

	# Calculate child positions AHEAD of selected node
	target_position = (spacing + selected_size.x)
	i = self.selected_child + 1
	while i < self.get_child_count():
		var child := self.get_child(i)
		if child == label:
			i += 1
			continue
		#(child as Control).position.x = target_position
		var tween := child.create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(child, "position", Vector2(target_position, 0), duration)
		var size_tween := child.create_tween()
		size_tween.tween_property(child, "size", unselected_size, duration)
		target_position += spacing + unselected_size.x
		i += 1


func _on_child_entered_tree(child: Node) -> void:
	if not child is Control:
		return
	var control := child as Control
	var tween := control.create_tween()
	control.modulate = Color(1, 1, 1, 0)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "modulate", Color(1, 1, 1, 1), duration)
	var size_tween := control.create_tween()
	size_tween.tween_property(control, "size", unselected_size, duration)


func _on_child_selected() -> void:
	var child := get_child(self.selected_child)
	if not child:
		return
	if not child is Control:
		return
	var node := child as Control
	node.grab_focus()
	child_selected.emit(child)
	if not child is GameTile:
		return
	var tile := child as GameTile
	if tile.is_library_tile:
		self.text = tile.text
		return
	if not tile.library_item:
		return
	self.text = tile.library_item.name


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_right"):
		# If the user is at the end of the list, pop the first element and
		# push it to the end
		if self.selected_child == self.get_child_count() - 1:
			var first := self.get_child(0)
			if not first:
				return
			self.move_child(first, -1)
			_on_child_selected()
		else:
			self.selected_child += 1
	elif event.is_action_released("ui_left"):
		# If the user is at the beginning of the list, pop the last element
		# and push it to the front
		if self.selected_child == 0:
			var last := self.get_child(-1)
			if not last:
				return
			self.move_child(last, 0)
			_on_child_selected()
		else:
			self.selected_child -= 1

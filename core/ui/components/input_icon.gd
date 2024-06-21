@tool
@icon("res://assets/editor-icons/tabler-xbox-a-filled.svg")
extends HBoxContainer
class_name InputIcon

var input_icons := load("res://core/systems/input/input_icon_manager.tres") as InputIconManager

var label := Label.new()
var textures: Array[Texture] = []
var texture_rects: Array[TextureRect] = []
var internal_children: Array[Node] = []

## Optional text to display next to the icon(s)
@export var text: String = "":
	set(_text):
		text = _text
		label.text = text
		label.visible = !text.is_empty()

## Icon path can be either an action name defined in the action map, or an input
## path (e.g. "joypad/south", "key/a", etc.).
@export var path: String = "":
	set(_path):
		path = _path
		if not is_inside_tree():
			return
		if path == "":
			self.visible = false
			return
		if force_type > 0:
			self.textures = input_icons.parse_path(path, force_mapping, force_type - 1)
		else:
			self.textures = input_icons.parse_path(path, force_mapping)
		
		# If no textures are found, become invisible
		self.visible = !self.textures.is_empty()
		
		# Remove old children
		for child in internal_children.duplicate():
			_remove_internal_child(child)
		internal_children.clear()
		
		# Add new children
		var i := 0
		for texture in self.textures:
			if i > 0:
				var lbl := Label.new()
				lbl.text = "+"
				self._add_internal_child(lbl)
			var rect := TextureRect.new()
			rect.texture = texture
			self._add_internal_child(rect)
			i += 1

		# Ensure the max width triggers
		var _w := self.max_width
		self.max_width = _w

## Whether or not an icon should be displayed
@export_enum("Both", "Keyboard/Mouse", "Controller") var show_only: int = 0:
	set(_show_only):
		show_only = _show_only
		if Engine.is_editor_hint():
			return
		_on_input_type_changed(input_icons.last_input_type)

## Force the icon to always show the given type of icon
@export_enum("None", "Keyboard/Mouse", "Controller") var force_type: int = 0:
	set(_force_type):
		force_type = _force_type
		if Engine.is_editor_hint():
			return
		_on_input_type_changed(input_icons.last_input_type)

## Force using the given icon mapping for a particular device
@export var force_mapping: String = "":
	set(_mapping):
		force_mapping = _mapping
		if is_inside_tree():
			var _p := self.path
			self.path = _p

## The maximum width of each icon texture
@export var max_width: int = 40:
	set(_max_width):
		max_width = _max_width
		if not is_inside_tree():
			return
		for child: Node in internal_children:
			if not child is TextureRect:
				continue
			var texture_rect := child as TextureRect
			if max_width < 0:
				texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			else:
				texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				texture_rect.custom_minimum_size.x = max_width
				if texture_rect.texture:
					texture_rect.custom_minimum_size.y = texture_rect.texture.get_height() * max_width / texture_rect.texture.get_width()
				else:
					texture_rect.custom_minimum_size.y = texture_rect.custom_minimum_size.x
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _ready():
	# Add the children
	self.add_child(label)
	# Only listen for input type changes if no mapping is forced
	if self.force_mapping.is_empty():
		input_icons.input_type_changed.connect(_on_input_type_changed)
	self.path = path
	self.max_width = max_width


func _on_input_type_changed(input_type: InputIconManager.InputType):
	if show_only == 0 or \
		(show_only == 1 and input_type == InputIconManager.InputType.KEYBOARD_MOUSE) or \
		(show_only == 2 and input_type == InputIconManager.InputType.GAMEPAD):
		self.visible = true
		self.path = path
		var width := self.max_width
		self.max_width = width
	else:
		self.visible = false


func _add_internal_child(child: Node) -> void:
	self.internal_children.append(child)
	self.add_child(child)
	

func _remove_internal_child(child: Node) -> void:
	self.remove_child(child)
	child.queue_free()
	var idx := self.internal_children.find(child)
	if idx < 0:
		return
	self.internal_children.remove_at(idx)

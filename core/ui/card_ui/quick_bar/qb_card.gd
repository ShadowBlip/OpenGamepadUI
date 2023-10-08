@tool
@icon("res://assets/editor-icons/card-bulleted.svg")
extends Container
class_name QuickBarCard

# DEPRECATED

signal pressed
signal button_up
signal button_down
signal toggled(pressed: bool)
signal toggled_on
signal toggled_off
signal nonchild_focused

@export_category("Card")
@export var title := "Section"
@export var is_toggled := false

@onready var label := $%SectionLabel
@onready var highlight := $%HighlightTexture
@onready var content_container := $%ContentContainer
@onready var focus_group_setter := $%FocusGroupSetter as FocusGroupSetter

var focus_group: FocusGroup
var logger := Log.get_logger("QBCard", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	pressed.connect(_on_pressed)
	theme_changed.connect(_on_theme_changed)
	_on_theme_changed()
	label.text = title
	
	# Do nothing if running in the editor
	if Engine.is_editor_hint():
		return
	
	# Resize any children that are Control nodes
	for child in content_container.get_children():
		# If the node is a control, resize it based on its children
		if child.get_class() == "Control":
			for c in child.get_children():
				if not c is Control:
					continue
				(child as Control).custom_minimum_size += c.size
	
	# Try and find a FocusGroup in the content to focus
	focus_group = _find_child_focus_group(content_container.get_children())
	focus_group_setter.target = focus_group


func _on_theme_changed() -> void:
	# Configure the highlight texture from the theme
	var highlight_texture := get_theme_icon("highlight", "ExpandableCard")
	if highlight_texture:
		highlight.texture = highlight_texture


# Recursively searches for FocusGroups in the given array of nodes. Returns the
# first one it finds
func _find_child_focus_group(nodes: Array[Node]) -> FocusGroup:
	if nodes.size() == 0:
		logger.debug("No children to check for FocusGroup.")
		return null

	for node in nodes:
		var focusable: Node
		logger.debug("Considering node: " + node.name)
		# Check if node is a child FocusGroup
		if node is FocusGroup:
			return node
		# Otherwise try and recursively find a child that can be focused
		logger.debug("Node: " + node.name + " is not a FocusGroup. Checking its children.")
		focusable = _find_child_focus_group(node.get_children())
		if focusable:
			return focusable
	logger.debug("No child FocusGroup was found.")
	return null


func _on_focus() -> void:
	# If the card gets focused, and its already expanded, that means we've
	# the user has focused outside the card, and we should shrink to hide the
	# content
	if is_toggled:
		_on_pressed()


func _on_unfocus() -> void:
	# If a child focus group is focused, don't do anything. That means that
	if not focus_group:
		logger.warn("No focus group defined!")
		return

	# a child node is focused and we want the card to remain "selected"
	if focus_group.is_in_focus_stack():
		return
	
	nonchild_focused.emit()


func _on_pressed() -> void:
	is_toggled = !is_toggled
	if is_toggled:
		toggled_on.emit()
	else:
		toggled_off.emit()
	
	toggled.emit(is_toggled)


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()

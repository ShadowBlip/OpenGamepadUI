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
@export var is_toggled := false:
	set(v):
		is_toggled = v
		if is_toggled:
			toggled_on.emit()
		else:
			toggled_off.emit()
		toggled.emit(is_toggled)

@onready var header_container := $%HeaderContainer as VBoxContainer
@onready var label := $%SectionLabel as Label
@onready var highlight := $%HighlightTexture as TextureRect
@onready var content_container := $%ContentContainer as VBoxContainer
@onready var focus_group_setter := $%FocusGroupSetter as FocusGroupSetter
@onready var smooth_scroll := $SmoothScrollEffect as SmoothScrollEffect
@onready var grower := $GrowerEffect as GrowerEffect

var focus_group: FocusGroup
var logger := Log.get_logger("QBCard", Log.LEVEL.INFO)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = title

	# Do nothing if running in the editor
	if Engine.is_editor_hint():
		return

	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	button_up.connect(_on_button_up)
	theme_changed.connect(_on_theme_changed)

	# Find the parent theme and update if required
	var effective_theme := ThemeUtils.get_effective_theme(self)
	if effective_theme:
		_on_theme_changed()

	# Try to find a scroll container to do smooth scrolling on expansion
	var scroll_container := find_parent("ScrollContainer")
	if scroll_container and scroll_container is ScrollContainer:
		smooth_scroll.target = scroll_container
		var on_grow_finished := func():
			smooth_scroll.scroll(self)
		grower.effect_finished.connect(on_grow_finished)

	# Auto-close when visibility is lost
	var on_hidden := func():
		is_toggled = false
	hidden.connect(on_hidden)

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


## Add the given content as the header to the card. Disables the section header
## when used.
func add_header(content: Control, alignment: BoxContainer.AlignmentMode) -> void:
	var add_to_card := func():
		label.visible = false
		header_container.visible = true
		header_container.alignment = alignment
		header_container.add_child(content)
	if self.is_node_ready():
		add_to_card.call()
	else:
		self.ready.connect(add_to_card)


## Add the given content to the card
func add_content(content: Control) -> void:
	var nodes: Array[Node] = [content]
	var add_to_card := func():
		focus_group = _find_child_focus_group(nodes)
		content_container.add_child(content)
		focus_group_setter.target = focus_group
	if self.is_node_ready():
		add_to_card.call()
	else:
		self.ready.connect(add_to_card)


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
		_on_button_up()


func _on_unfocus() -> void:
	# If a child focus group is focused, don't do anything. That means that
	if not focus_group:
		logger.warn("No focus group defined!")
		return

	# a child node is focused and we want the card to remain "selected"
	if focus_group.is_in_focus_stack():
		return
	
	nonchild_focused.emit()


func _on_button_up() -> void:
	is_toggled = !is_toggled
	if is_toggled:
		toggled_on.emit()
	else:
		toggled_off.emit()
	
	toggled.emit(is_toggled)


func _gui_input(event: InputEvent) -> void:
	var is_valid := [event is InputEventAction, event is InputEventKey]
	if not true in is_valid:
		return
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()


func _input(event: InputEvent) -> void:
	if not is_toggled:
		return
	if not event.is_action("ogui_east"):
		return
	if not event.is_released():
		return

	# Only process input if a child node has focus
	#var focus_owner := get_viewport().gui_get_focus_owner()
	#if not self.is_ancestor_of(focus_owner):
	#	return

	# Handle back input
	is_toggled = false

	# Stop the event from propagating
	#logger.debug("Consuming input event '{action}' for node {n}".format({"action": action, "n": str(self)}))
	get_viewport().set_input_as_handled()

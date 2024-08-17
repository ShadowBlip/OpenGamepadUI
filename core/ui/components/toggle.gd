@tool
@icon("res://assets/editor-icons/twotone-toggle-off.svg")
extends BoxContainer
class_name Toggle

signal button_down
signal button_up
signal pressed
signal toggled(pressed: bool)

@export_category("Label Settings")
@export var text: String = "Setting"
@export var separator_visible: bool = false
@export var show_label := true:
	set(v):
		show_label = v
		if label:
			label.visible = v
		notify_property_list_changed()
@export var description: String = "":
	set(v):
		description = v
		if description_label:
			description_label.text = v
			description_label.visible = v != ""
		notify_property_list_changed()

@export_category("Toggle Settings")
@export var button_pressed := false:
	set(v):
		button_pressed = v
		if check_button:
			check_button.button_pressed = v
		notify_property_list_changed()

@export var disabled := false:
	set(v):
		disabled = v
		if check_button:
			check_button.disabled = v
		notify_property_list_changed()

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var check_button := $%CheckButton as CheckButton
@onready var hsep := $%HSeparator as HSeparator
@onready var panel := $%PanelContainer as PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text
	description_label.text = description
	description_label.visible = description != ""
	hsep.visible = separator_visible
	check_button.button_pressed = button_pressed
	check_button.disabled = disabled

	if Engine.is_editor_hint():
		return

	# Update colors on focus
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	theme_changed.connect(_on_theme_changed)

	# Find the parent theme and update if required
	var effective_theme := ThemeUtils.get_effective_theme(self)
	if effective_theme:
		_on_theme_changed()


func _on_theme_changed() -> void:
	# Get the style from the set theme so it can be set on the panel container
	var normal_stylebox := get_theme_stylebox("panel", "SelectableText").duplicate()
	panel.add_theme_stylebox_override("panel", normal_stylebox)
	check_button.modulate = get_theme_color("color", "Toggle")


func _on_focus(focused: bool) -> void:
	panel.remove_theme_stylebox_override("panel")
	if focused:
		var focus_stylebox := get_theme_stylebox("panel_focus", "SelectableText").duplicate()
		panel.add_theme_stylebox_override("panel", focus_stylebox)
		return
	var normal_stylebox := get_theme_stylebox("panel", "SelectableText").duplicate()
	panel.add_theme_stylebox_override("panel", normal_stylebox)


func _gui_input(event: InputEvent) -> void:
	var is_valid := [event is InputEventAction, event is InputEventKey]
	if not true in is_valid:
		return
	if not event.is_action("ui_accept"):
		return

	if event.is_pressed():
		button_pressed = !button_pressed
		toggled.emit(button_pressed)
		button_down.emit()
		pressed.emit()
	else:
		button_up.emit()

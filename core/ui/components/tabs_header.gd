@tool
extends HBoxContainer
class_name TabsHeader

var tab_label_scene := load("res://core/ui/components/tab_label.tscn") as PackedScene
var current_tab: TabLabel

@export var tabs_state: TabContainerState
@export var show_left_separator := false
@export var show_right_separator := false

@onready var l_sep := $%LSeparator
@onready var r_sep := $%RSeparator
@onready var container := $%TabLabelContainer
@onready var scroll_container := $%EnhancedScrollContainer as EnhancedScrollContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	l_sep.visible = show_left_separator
	r_sep.visible = show_right_separator
	if not tabs_state:
		return
	if tabs_state.tabs_text.size() == 0:
		return

	# Create all the tab labels
	for tab_text in tabs_state.tabs_text:
		var tab := tab_label_scene.instantiate()
		tab.text = tab_text
		container.add_child(tab)

	# Don't run in the editor
	if Engine.is_editor_hint():
		return

	# Set the currently selected tab
	_on_tab_changed(tabs_state.current_tab)

	# Listen for tab changes
	tabs_state.tab_changed.connect(_on_tab_changed)
	tabs_state.tab_added.connect(_on_tab_added)
	tabs_state.tab_removed.connect(_on_tab_removed)


func _on_tab_changed(tab: int) -> void:
	for tab_label in container.get_children():
		tab_label.selected = false
	current_tab = container.get_child(tab)
	current_tab.selected = true
	if not current_tab:
		return
	var target_position := current_tab.position.x - (current_tab.size.x / 2)
	if target_position < 0:
		target_position = 0
	var tween := get_tree().create_tween()
	tween.tween_property(scroll_container, "scroll_horizontal", target_position, 0.2)


func _on_tab_added(tab_text: String, _node: ScrollContainer) -> void:
	var tab := tab_label_scene.instantiate()
	tab.text = tab_text
	container.add_child(tab)


func _on_tab_removed(tab_text: String) -> void:
	for child in container.get_children():
		if child.get("text") == null:
			continue
		if child.text != tab_text:
			continue
		child.queue_free()
		break


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not tabs_state:
		return
	var is_tab_action := event.is_action("ogui_tab_left") or event.is_action("ogui_tab_right")
	if not is_tab_action:
		return
	
	var num_tabs: int = tabs_state.tabs_text.size()
	var next_tab: int = tabs_state.current_tab
	if event.is_action_pressed("ogui_tab_right"):
		next_tab += 1
	if event.is_action_pressed("ogui_tab_left"):
		next_tab -= 1
	
	if next_tab < 0:
		next_tab = num_tabs - 1
	if next_tab + 1 > num_tabs:
		next_tab = 0
	tabs_state.current_tab = next_tab
	get_viewport().set_input_as_handled()

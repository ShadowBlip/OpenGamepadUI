@tool
extends HBoxContainer

signal button_down
signal button_up
signal pressed
signal toggled(pressed: bool)

@export var text: String = "Setting"
@export var show_label := true:
	set(v):
		show_label = v
		if label:
			label.visible = v
		notify_property_list_changed()

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

@onready var label := $Label as Label
@onready var check_button := $CheckButton as CheckButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text
	check_button.button_pressed = button_pressed
	check_button.disabled = disabled
	check_button.focus_neighbor_bottom = "../" + str(focus_neighbor_bottom)
	check_button.focus_neighbor_left = "../" + str(focus_neighbor_left)
	check_button.focus_neighbor_right = "../" + str(focus_neighbor_right)
	check_button.focus_neighbor_top = "../" + str(focus_neighbor_top)
	check_button.focus_previous = "../" + str(focus_previous)
	check_button.focus_next = "../" + str(focus_next)
	
	# Wire up the button signals
	var on_button_down := func():
		button_down.emit()
	check_button.button_down.connect(on_button_down)
	var on_button_up := func():
		button_up.emit()
	check_button.button_up.connect(on_button_up)
	var on_pressed := func():
		pressed.emit()
	check_button.pressed.connect(on_pressed)
	var on_toggled := func(changed: bool):
		toggled.emit(changed)
	check_button.toggled.connect(on_toggled)


func _on_focus_entered():
	check_button.grab_focus()

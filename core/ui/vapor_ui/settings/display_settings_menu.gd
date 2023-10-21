extends Control

var SettingsManager := load("res://core/global/settings_manager.tres") as SettingsManager
var DisplayManager := load("res://core/global/display_manager.tres") as DisplayManager

@onready var scale_slider := $%ScaleSlider
@onready var display_rotation_dropdown := $VBoxContainer/RotateDisplay
@onready var target_display_dropdown := $VBoxContainer/TargetDisplay


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Populate dropdowns
	_add_rotation_options()
	_add_connector_options()
	
	var display_scale := SettingsManager.get_value("display", "scale", 1.0) as float
	scale_slider.value = display_scale
	get_window().content_scale_factor = display_scale
	scale_slider.value_changed.connect(_on_scale_changed)


func _on_scale_changed(value: float) -> void:
	get_window().content_scale_factor = value
	SettingsManager.set_value("display", "scale", value)


func _add_rotation_options():
	display_rotation_dropdown.clear()
	display_rotation_dropdown.add_item("Normal")
	display_rotation_dropdown.add_item("Left Up")
	display_rotation_dropdown.add_item("Upsidedown")
	display_rotation_dropdown.add_item("Right Up")


func _add_connector_options():
	var connector_names = DisplayManager.get_list_of_connectors()
	target_display_dropdown.clear()
	for name in connector_names:
		target_display_dropdown.add_item(name)


func _on_rotate_display_item_selected(index):
	DisplayManager.gamescope.set_rotation(index)

func _on_target_display_item_selected(index):
	var connector_id = DisplayManager.get_list_of_connector_ids()
	DisplayManager.target_connector(connector_id[index])

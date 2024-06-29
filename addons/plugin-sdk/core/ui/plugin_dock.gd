@tool
extends Control

## Main menu for the Plugin SDK

@onready var create_plugin_window := $%CreatePluginWindow as Window
@onready var create_plugin_button := $%CreatePluginButton as Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_plugin_button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	print("PRESSED!")
	create_plugin_window.show()

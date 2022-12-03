extends Control

@onready var plugin_name_label := $MarginContainer/VBoxContainer/PluginNameLabel
@onready var plugin_texture := $MarginContainer/VBoxContainer/HBoxContainer/TextureRect
@onready var author_label := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AuthorLabel
@onready var summary_label := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SummaryLabel
@onready var install_button := $MarginContainer/HBoxContainer/InstallButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

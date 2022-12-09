extends Control

var logger : Log.Logger
@onready var plugin_loader: PluginLoader = get_node("/root/Main/PluginLoader")
@onready var plugin_name_label := $MarginContainer/VBoxContainer/PluginNameLabel
@onready var plugin_texture := $MarginContainer/VBoxContainer/HBoxContainer/TextureRect
@onready var author_label := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AuthorLabel
@onready var summary_label := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SummaryLabel
@onready var install_button := $MarginContainer/HBoxContainer/InstallButton

var download_url: String 
var project_url: String
var sha256: String
var plugin_id: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	install_button.button_up.connect(_on_install_button)

func set_logger(name: String) -> void:
	logger = Log.get_logger(name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_install_button() -> void:
	plugin_loader.install_plugin(plugin_id, download_url, sha256)

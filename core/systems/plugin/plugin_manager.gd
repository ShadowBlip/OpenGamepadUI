@icon("res://assets/editor-icons/codesandbox-logo-fill.svg")
extends Node
class_name PluginManager

var PluginLoader := load("res://core/global/plugin_loader.tres") as PluginLoader


func _init() -> void:
	PluginLoader.init(self)

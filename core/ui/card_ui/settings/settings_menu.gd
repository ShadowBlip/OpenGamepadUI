extends Control

var version := preload("res://core/global/version.tres") as Version

@onready var version_label := $%VersionLabel as Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	version_label.text = "v" + str(version.core)

extends RefCounted
class_name Notification

enum LEVEL {
	LOW,
	NORMAL,
	CRITICAL,
}

signal action_taken
signal dismissed

var text: String
var icon: Texture2D
var timeout: float = 5.0
var level: LEVEL = LEVEL.NORMAL
var action_text: String
var metadata: Variant


func _init(txt: String) -> void:
	text = txt

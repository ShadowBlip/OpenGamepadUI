extends Control

@onready var text_edit := $CenterContainer/TextEdit
@onready var osk := $OnScreenKeyboard

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var context := KeyboardContext.new(KeyboardContext.TYPE.GODOT, text_edit, _on_submit)
	osk.open(context)


func _on_submit():
	pass

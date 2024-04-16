extends GutTest

@onready var text_edit := $CenterContainer/TextEdit
@onready var osk := $OnScreenKeyboard

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var context := KeyboardContext.new(KeyboardContext.TYPE.GODOT, text_edit)
	osk.open()
	print(text_edit.is_caret_visible())


func _on_submit(text: String):
	print("Submitted: ", text)

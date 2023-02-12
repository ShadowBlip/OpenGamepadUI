extends TextEdit
class_name SearchBar

signal search_submitted(text: String)

@export var keyboard: KeyboardInstance = preload("res://core/global/keyboard_instance.tres")
var keyboard_context := KeyboardContext.new(KeyboardContext.TYPE.GODOT, self)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_changed.connect(_on_text_changed)


func _on_text_changed() -> void:
	search_submitted.emit(text)


# Handle GUI input to request opening the on-screen keyboard.
func _gui_input(event: InputEvent) -> void:
	if not has_focus():
		return
	if event.is_action_released("ogui_south"):
		keyboard.open(keyboard_context)

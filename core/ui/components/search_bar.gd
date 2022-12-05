extends TextEdit
class_name SearchBar

signal search_submitted(text: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_changed.connect(_on_text_changed)

func _on_text_changed() -> void:
	search_submitted.emit(text)

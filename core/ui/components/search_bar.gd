extends TextEdit
class_name SearchBar

signal search_submitted(text: String)

var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var library_state := load("res://assets/state/states/library.tres")

var keyboard_context := KeyboardContext.new(KeyboardContext.TYPE.GODOT, self)
@export var keyboard: KeyboardInstance = preload("res://core/global/keyboard_instance.tres")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_changed.connect(_on_text_changed)


func _on_text_changed() -> void:
	search_submitted.emit(text)


# Handle GUI input to request opening the on-screen keyboard.
func _gui_input(event: InputEvent) -> void:
	if not has_focus():
		return
	if not event.is_action_released("ogui_south"):
		return
	
	if state_machine.current_state() != library_state:
		state_machine.push_state(library_state)
		
	keyboard.open(keyboard_context)

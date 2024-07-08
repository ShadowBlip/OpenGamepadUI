@icon("res://assets/editor-icons/dialog-2-bold.svg")
@tool
extends Control
class_name Dialog

## Emitted when the dialog window is opened
signal opened
## Emitted when the dialog window is closed
signal closed
## Emitted when the user selects an option
signal choice_selected(accepted: bool)

## Text to display in the dialog box
@export var text: String:
	set(v):
		text = v
		if label:
			label.text = v
## Confirm button text
@export var confirm_text: String = "OK":
	set(v):
		confirm_text = v
		if confirm_button:
			confirm_button.text = v
## Cancel button text
@export var cancel_text: String = "Cancel":
	set(v):
		cancel_text = v
		if cancel_button:
			cancel_button.text = v
@export var cancel_visible: bool = true:
	set(v):
		cancel_visible = v
		if cancel_button:
			cancel_button.visible = v
## Close the dialog when the user selects an option
@export var close_on_selected := true

@onready var label := $%Label as Label
@onready var confirm_button := $%ConfirmButton as Button
@onready var cancel_button := $%CancelButton as Button
@onready var fade_effect := $%FadeEffect as Effect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	confirm_button.button_up.connect(_on_selected.bind(true))
	cancel_button.button_up.connect(_on_selected.bind(false))


## Invoked when confirm or cancel is selected
func _on_selected(accepted: bool) -> void:
	if close_on_selected:
		closed.emit()
	choice_selected.emit(accepted)


## Opens the dialog box with the given settings
func open(message: String = "", confirm_txt: String = "", cancel_txt: String = "") -> void:
	if message != "":
		text = message
	if confirm_txt != "":
		confirm_text = confirm_txt
	if cancel_txt != "":
		cancel_text = cancel_txt

	opened.emit()
	await fade_effect.effect_finished
	confirm_button.grab_focus.call_deferred()

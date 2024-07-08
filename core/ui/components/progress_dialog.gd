@icon("res://assets/editor-icons/dialog-2-bold.svg")
@tool
extends Control
class_name ProgressDialog

## Emitted when the dialog window is opened
signal opened
## Emitted when the dialog window is closed
signal closed
## Emitted when the user cancels the operation
signal cancelled

## Text to display in the dialog box
@export var text: String:
	set(v):
		text = v
		if label:
			label.text = v
## Confirm button text
@export var value: float = 0:
	set(v):
		value = v
		if progress_bar:
			progress_bar.value = v
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
@onready var progress_bar := $%ProgressBar as ProgressBar
@onready var cancel_button := $%CancelButton as Button
@onready var fade_effect := $%FadeEffect as Effect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cancel_button.button_up.connect(_on_selected.bind())


## Invoked when confirm or cancel is selected
func _on_selected() -> void:
	if close_on_selected:
		closed.emit()
	cancelled.emit()


## Opens the dialog box with the given settings
func open(message: String = "", cancel_txt: String = "") -> void:
	if message != "":
		text = message
	if cancel_txt != "":
		cancel_text = cancel_txt

	opened.emit()
	await fade_effect.effect_finished
	cancel_button.grab_focus.call_deferred()


## Closes the progress dialog
func close() -> void:
	closed.emit()

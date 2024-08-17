@tool
@icon("res://assets/editor-icons/icon.svg")
extends PanelContainer
class_name CardInputIconButton

signal pressed
signal button_up
signal button_down

@export_category("Button")
@export var disabled := false
@export_category("Mouse")
@export var click_focuses := true

var logger := Log.get_logger("CardInputIconButton")

@onready var input_icon := %InputIcon as InputIcon
@onready var highlight := $%HighlightTexture as TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect signals
	theme_changed.connect(_on_theme_changed)

	# Find the parent theme and update if required
	var effective_theme := ThemeUtils.get_effective_theme(self)
	if effective_theme:
		_on_theme_changed()


func _on_theme_changed() -> void:
	# Configure the highlight texture from the theme
	var highlight_texture := get_theme_icon("highlight", "CardButton")
	if highlight_texture:
		highlight.texture = highlight_texture


## Set the target input icon's icon mapping
func set_target_device_icon_mapping(mapping_name: String) -> void:
	input_icon.force_mapping = mapping_name


## Configures the button for the given mappable event. If a path cannot be found,
## this will return an error.
func set_target_icon(capability: String) -> int:
	# Convert the capability into an input icon path
	var path := InputPlumberEvent.get_joypad_path(capability)
	if path.is_empty():
		logger.warn("No input path is defined for capability: " + capability)
		return ERR_DOES_NOT_EXIST
	input_icon.path = path

	return OK


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and not click_focuses:
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
	if not event.is_action("ui_accept"):
		return
	if event.is_pressed():
		button_down.emit()
		pressed.emit()
	else:
		button_up.emit()

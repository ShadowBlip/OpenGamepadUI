@tool
@icon("res://assets/editor-icons/button.svg")
extends Control
class_name CardMappingButton

signal pressed
signal button_up
signal button_down

@export_category("Button")
@export var disabled := false

@export_category("Label")
@export var text := "Button":
	set(v):
		text = v
		if target_label:
			target_label.text = v
@export var label_settings: LabelSettings:
	set(v):
		label_settings = v
		if target_label:
			target_label.label_settings = v
@export var horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER:
	set(v):
		horizontal_alignment = v
		if target_label:
			target_label.horizontal_alignment = v
@export var vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER:
	set(v):
		vertical_alignment = v
		if target_label:
			target_label.vertical_alignment = v
@export var autowrap_mode: TextServer.AutowrapMode:
	set(v):
		autowrap_mode = v
		if target_label:
			target_label.autowrap_mode = v
@export var uppercase := true:
	set(v):
		uppercase = v
		if target_label:
			target_label.uppercase = v

@export_category("Mouse")
@export var click_focuses := true

var _capability: String = ""
var _direction: String = ""
var _mappings: Array[InputPlumberMapping] = []
var logger := Log.get_logger("CardMappingButton", Log.LEVEL.INFO)

@onready var source_label := $%SourceLabel as Label
@onready var target_label := $%TargetLabel as Label
@onready var highlight := $%HighlightTexture as TextureRect
@onready var source_icon := $%SourceInputIcon as InputIcon
@onready var target_icon := $%TargetInputIcon as InputIcon


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Configure the label
	target_label.text = text
	target_label.label_settings = label_settings
	target_label.horizontal_alignment = horizontal_alignment
	target_label.vertical_alignment = vertical_alignment
	target_label.autowrap_mode = autowrap_mode
	target_label.uppercase = uppercase

	if Engine.is_editor_hint():
		return

	# Connect signals
	theme_changed.connect(_on_theme_changed)

	# Find the parent theme and update if required
	var effective_theme := ThemeUtils.get_effective_theme(self)
	if effective_theme:
		_on_theme_changed()


## Set the source input icon's icon mapping
func set_source_device_icon_mapping(mapping_name: String) -> void:
	source_icon.force_mapping = mapping_name


## Set the target input icon's icon mapping
func set_target_device_icon_mapping(mapping_name: String) -> void:
	target_icon.force_mapping = mapping_name


## Configures the button for the given source capability
func set_source_capability(capability: String, direction: String = "") -> void:
	logger.debug("Setting source capabilibuddy: " + capability)
	if capability == "":
		return
	_capability = capability
	_direction = direction
	if not is_inside_tree():
		return
	if set_source_icon(capability, direction) != OK:
		logger.warn("No icon found for capability. Setting text instead.")
		source_label.visible = true
		source_icon.visible = false
		source_label.text = capability
		return
	source_label.visible = false
	source_icon.visible = true


## Configures the button for the given target capability
func set_target_capability(capability: String, direction: String = "") -> void:
	logger.debug("Setting target capabilibuddy: " + capability)
	if capability == "":
		return
	if set_target_icon(capability, direction) != OK:
		logger.warn("No icon found for capability. Setting text instead.")
		target_label.visible = true
		target_icon.visible = false
		target_label.text = capability
		return
	target_label.visible = false
	target_icon.visible = true


## Configures the button for the given mappable event. If a path cannot be found,
## this will return an error.
func set_source_icon(capability: String, direction: String = "") -> int:
	# Convert the capability into an input icon path
	var path := InputPlumberEvent.get_joypad_path(capability)
	if path.is_empty():
		logger.warn("No input path is defined for capability: " + capability)
		return ERR_DOES_NOT_EXIST
	if not direction.is_empty():
		path = "/".join([path, direction])
	source_icon.force_type = 2
	source_icon.path = path
	if source_icon.textures.is_empty():
		logger.debug("No texture found, hiding " + capability + " button.")
		self.visible = false
	else:
		self.visible = true

	return OK


## Configures the button for the given mappable event. If a path cannot be found,
## this will return an error.
func set_target_icon(capability: String, direction: String = "") -> int:
	# Convert the capability into an input icon path
	var path := InputPlumberEvent.get_joypad_path(capability)
	if path.is_empty():
		logger.warn("No input path is defined for capability: " + capability)
		return ERR_DOES_NOT_EXIST
	if not direction.is_empty():
		path = "/".join([path, direction])
	target_icon.path = path

	return OK


func _on_theme_changed() -> void:
	# Configure the highlight texture from the theme
	var highlight_texture := get_theme_icon("highlight", "CardButton")
	if highlight_texture:
		highlight.texture = highlight_texture


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

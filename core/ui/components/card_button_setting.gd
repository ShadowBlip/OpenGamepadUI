@tool
extends BoxContainer
class_name CardButtonSetting

signal pressed
signal button_up
signal player_button_up(metaname: String, dbus_path: String)
signal button_down
signal player_button_down(metaname: String, dbus_path: String)

@export_category("Label Settings")
@export var text: String = "Setting"
@export var separator_visible: bool = false
@export var show_label := true:
	set(v):
		show_label = v
		if label:
			label.visible = v
		notify_property_list_changed()
@export var description: String = "":
	set(v):
		description = v
		if description_label:
			description_label.text = v
			description_label.visible = v != ""
		notify_property_list_changed()

@export_category("Button Settings")
@export var button_text := "Button":
	set(v):
		button_text = v
		if card_button:
			card_button.text = v
		notify_property_list_changed()

@export var disabled := false:
	set(v):
		disabled = v
		if card_button:
			card_button.disabled = v
		notify_property_list_changed()

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var card_button := $%CardButton as CardButton
@onready var hsep := $%HSeparator as HSeparator
@onready var panel := $%PanelContainer as PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text
	description_label.text = description
	description_label.visible = description != ""
	hsep.visible = separator_visible

	if Engine.is_editor_hint():
		return

	# Update colors on focus
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	theme_changed.connect(_on_theme_changed)

	# Connect button signals
	card_button.text = button_text
	card_button.pressed.connect(self.emit_signal.bind("pressed"))
	card_button.button_up.connect(self.emit_signal.bind("button_up"))
	card_button.button_down.connect(self.emit_signal.bind("button_down"))
	var on_player_button := func(metaname: String, dbus_path: String, sig: String):
		self.emit_signal(sig, metaname, dbus_path)
	card_button.player_button_up.connect(on_player_button.bind("player_button_up"))
	card_button.player_button_down.connect(on_player_button.bind("player_button_up"))

	# Find the parent theme and update if required
	var effective_theme := ThemeUtils.get_effective_theme(self)
	if effective_theme:
		_on_theme_changed()


func _on_theme_changed() -> void:
	# Get the style from the set theme so it can be set on the panel container
	var normal_stylebox := get_theme_stylebox("panel", "SelectableText").duplicate()
	panel.add_theme_stylebox_override("panel", normal_stylebox)


func _on_focus(focused: bool) -> void:
	if focused:
		card_button.grab_focus()

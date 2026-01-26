@icon("res://assets/editor-icons/button.svg")
@tool
extends Component
class_name ComponentButton

signal pressed
signal button_up
signal player_button_up(metaname: String, dbus_path: String)
signal button_down
signal player_button_down(metaname: String, dbus_path: String)

@export var text: String:
	set(v):
		text = v
		_set_implementation_property("text", v)
@export var disabled := false:
	set(v):
		disabled = v
		_set_implementation_property("disabled", v)
@export var click_focuses := false:
	set(v):
		click_focuses = v
		_set_implementation_property("click_focuses", v)
@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		_set_implementation_property("icon_texture", v)


func _ready() -> void:
	var components := get_component_map()
	if Engine.is_editor_hint():
		components = load("res://core/ui/etoile_ui/etoile_components.tres")
	else:
		assert(components != null, "Unable to detect user interface to build component")
	implementation = components.build(ComponentsMap.Type.Button)
	_connect_implementation_signal("pressed", _on_pressed)
	_connect_implementation_signal("button_up", _on_button_up)
	_connect_implementation_signal("player_button_up", _on_player_button_up)
	_connect_implementation_signal("button_down", _on_button_down)
	_connect_implementation_signal("player_button_down", _on_player_button_down)
	disabled = disabled
	click_focuses = click_focuses
	icon_texture = icon_texture
	text = text
	add_child(implementation)


func _on_pressed() -> void:
	pressed.emit()


func _on_button_up() -> void:
	button_up.emit()


func _on_player_button_up(metaname: String, dbus_path: String) -> void:
	player_button_up.emit(metaname, dbus_path)


func _on_button_down() -> void:
	button_down.emit()


func _on_player_button_down(metaname: String, dbus_path: String) -> void:
	player_button_down.emit(metaname, dbus_path)

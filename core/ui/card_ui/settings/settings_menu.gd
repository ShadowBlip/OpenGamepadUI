extends Control

var settings_state_machine := preload("res://assets/state/state_machines/settings_state_machine.tres") as StateMachine
var version := preload("res://core/global/version.tres") as Version

@onready var version_label := $%VersionLabel
@onready var setting_buttons_container: VBoxContainer = $%SettingButtonsContainer
@onready var focus_group := $%FocusGroup as FocusGroup
@onready var section_label := $%SectionLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	version_label.text = "v" + str(version.core)
	settings_state_machine.state_changed.connect(_on_settings_state_changed)


func _on_settings_state_changed(_from: State, to: State) -> void:
	var text := to.name
	text = text.capitalize()
	text = text.replace("_", " ")
	section_label.text = text

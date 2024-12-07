extends MarginContainer

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var network_manager := load("res://core/systems/network/network_manager.tres") as NetworkManagerInstance
var state_machine := load("res://assets/state/state_machines/first_boot_state_machine.tres") as StateMachine
var no_networking_state := load("res://assets/state/states/first_boot_finished.tres") as State
var button_scene := load("res://core/ui/components/card_button.tscn") as PackedScene
@onready var button_container := %VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Delete the old buttons
	for child in button_container.get_children():
		if child is CardButton:
			child.queue_free()
	
	# Create a button for each locale
	for locale in TranslationServer.get_loaded_locales():
		var language := locale.split("_")[0]
		var language_name := tr(TranslationServer.get_language_name(language))
		
		# Create the button and set the language name
		var button := button_scene.instantiate() as CardButton
		button.button_up.connect(_on_button_up.bind(locale))
		button.text = language_name
		
		# Add the button to the scene
		button_container.add_child(button)


func _on_button_up(locale: String) -> void:
	# Set and save locale
	TranslationServer.set_locale(locale)
	settings_manager.set_value("general", "locale", locale)

	# Determine the next state to go to
	if not network_manager.is_running():
		state_machine.push_state(no_networking_state)
		return
	var next_state: State
	if network_manager.state >= network_manager.NM_STATE_CONNECTED_GLOBAL:
		next_state = load("res://assets/state/states/first_boot_plugin_select.tres") as State
	else:
		next_state = load("res://assets/state/states/first_boot_network.tres") as State
	state_machine.push_state(next_state)

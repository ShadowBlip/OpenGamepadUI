extends MarginContainer

var state_updater_scene := load("res://core/systems/state/state_updater.tscn") as PackedScene
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
		var language_name := TranslationServer.get_language_name(language)
		
		# Configure a state updater to change menu states when the button is pressed
		var state_updater := state_updater_scene.instantiate() as StateUpdater
		state_updater.state_machine = load("res://assets/state/state_machines/first_boot_state_machine.tres")
		state_updater.state = load("res://assets/state/states/first_boot_network.tres")
		state_updater.action = state_updater.ACTION.REPLACE
		state_updater.on_signal = "button_up"
		
		# Create the button and set the language name
		var button := button_scene.instantiate() as CardButton
		button.text = language_name
		button.add_child(state_updater)
		
		# Add the button to the scene
		button_container.add_child(button)

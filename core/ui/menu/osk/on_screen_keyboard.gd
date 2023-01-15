@tool
extends Control

signal keyboard_populated
signal layout_changed

@export var layout: Resource

const key_scene := preload("res://core/ui/components/button.tscn")

@onready var rows_container: VBoxContainer = $MarginContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not layout:
		return
	populate_keyboard()


# Populate the keyboard based on the selected layout
func populate_keyboard():
	# Clear the current layout
	for child in rows_container.get_children():
		rows_container.remove_child(child)
	
	# Populate the keyboard keys based on the given layout
	for r in (layout as KeyboardLayout).rows:
		var row: Array = r
		
		# Create an HBox Container for the row
		var container := HBoxContainer.new()
		rows_container.add_child(container)
		
		# Loop through the layout and create key buttons for each key
		for k in row:
			var key: KeyboardKeyConfig = k
			if not key:
				continue
			var button := key_scene.instantiate()
			if key.type == KeyboardKeyConfig.TYPE.CHAR and key.display != "":
				button.text = key.display
			
			container.add_child(button)
		
	keyboard_populated.emit()


# Sets the given keyboard layout and re-populates the keyboard
func set_layout(key_layout: KeyboardLayout):
	layout = key_layout
	populate_keyboard()
	layout_changed.emit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

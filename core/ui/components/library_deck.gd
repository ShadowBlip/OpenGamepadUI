@tool
@icon("res://assets/editor-icons/cards-outline.svg")
extends MarginContainer
class_name LibraryDeck

signal button_up
signal button_down
signal pressed
signal highlighted
signal unhighlighted

@onready var card_1 := $%GameCard1 as GameCard
@onready var card_2 := $%GameCard2 as GameCard
@onready var card_3 := $%GameCard3 as GameCard
@onready var timer := $%Timer as Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_unfocus)
	mouse_entered.connect(_on_focus)
	mouse_exited.connect(_on_unfocus)


## Set the texture on one of the cards in the library deck
func set_texture(idx: int, texture: Texture2D) -> void:
	match idx:
		0:
			card_1.set_texture(texture)
		1:
			card_2.set_texture(texture)
		2:
			card_3.set_texture(texture)


func _on_focus() -> void:
	highlighted.emit()


func _on_unfocus() -> void:
	unhighlighted.emit()


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()

extends Node
class_name Store

@export var store_name: String
@export_file("*.png") var store_image: String

@onready var store_manager: StoreManager = get_node("/root/Main/StoreManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("store")

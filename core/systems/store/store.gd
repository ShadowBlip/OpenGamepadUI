extends Node
class_name Store

signal home_loaded(results: Array)
signal installed_loaded(results: Array)
signal details_loaded(result: StoreItemDetails)
signal search_completed(results: Array)

# Globally unique store identifier
@export var store_id: String
# The display name of the store
@export var store_name: String
# A landscape banner image for the store
@export_file("*.png") var store_image: String
@export var logger_name := store_id
@export var log_level: Log.LEVEL = Log.LEVEL.INFO

@onready var logger := Log.get_logger(logger_name, log_level)


func _init() -> void:
	ready.connect(add_to_group.bind("store"))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func load_home():
	pass


func load_installed():
	pass


func load_details(id: String):
	pass


func search(str: String):
	pass

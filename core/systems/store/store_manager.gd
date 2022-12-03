extends Node
class_name StoreManager
@icon("res://assets/icons/tag.svg")

const REQUIRED_FIELDS: Array = ["store_id", "store_name", "store_image"]

signal store_registered(store: Store)

var _stores: Dictionary = {}
var logger := Log.get_logger("StoreManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var main: Main = get_parent()
	main.ready.connect(_on_parent_ready)


# Called when our parent is ready
func _on_parent_ready() -> void:
	var stores = get_tree().get_nodes_in_group("store")
	for store in stores:
		_register_store(store)


# Registers the given store with the store manager.
func _register_store(store: Store) -> void:
	if not _is_valid_store(store):
		logger.error("Invalid store defined! Ensure you have all required properties set: " + ",".join(REQUIRED_FIELDS))
		return
	_stores[store.store_id] = store
	store_registered.emit(store)


# Validates the given store and returns true if it has the required properties
# set.
func _is_valid_store(store: Store) -> bool:
	for field in REQUIRED_FIELDS:
		var data = store.get(field)
		if data == "":
			return false
	return true


# Returns the given store implementation by id
func get_store_by_id(id: String) -> Store:
	return _stores[id]


# Returns a list of all registered stores
func get_stores() -> Array:
	return _stores.values()

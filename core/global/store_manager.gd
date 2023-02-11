@icon("res://assets/icons/tag.svg")
extends Resource
class_name StoreManager

const REQUIRED_FIELDS: Array = ["store_id", "store_name", "store_image"]

signal store_registered(store: Store)
signal store_unregistered(store_id: String)

var _stores: Dictionary = {}
var logger := Log.get_logger("StoreManager")


# Registers the given store with the store manager.
func register_store(store: Store) -> void:
	if not _is_valid_store(store):
		logger.error("Invalid store defined! Ensure you have all required properties set: " + ",".join(REQUIRED_FIELDS))
		return
	_stores[store.store_id] = store
	store_registered.emit(store)


# Unregisters the store with the store manager
func unregister_store(store: Store) -> void:
	_stores.erase(store.store_id)
	store_unregistered.emit()


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

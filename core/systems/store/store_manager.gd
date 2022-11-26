extends Node
class_name StoreManager

signal store_registered(store: Store)

var _stores: Array = []

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
	_stores.push_back(store)
	store_registered.emit(store)


# Returns a list of all registered stores
func get_stores() -> Array:
	return _stores

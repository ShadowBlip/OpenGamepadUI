@icon("res://assets/icons/image.svg")
extends Node

const boxart_local_provider := preload("res://core/systems/boxart/boxart_local.tscn")
const REQUIRED_FIELDS: Array = ["provider_id"]

signal provider_registered(boxart: BoxArtProvider)
signal provider_unregistered(provider_id: String)

var logger := Log.get_logger("BoxArtManager")

# Map the layouts to different placeholders
const _placeholder_map = {
	BoxArtProvider.LAYOUT.GRID_PORTRAIT: preload("res://assets/images/placeholder-grid-portrait.png"),
	BoxArtProvider.LAYOUT.GRID_LANDSCAPE: preload("res://assets/images/placeholder-grid-landscape.png"),
	BoxArtProvider.LAYOUT.BANNER: preload("res://assets/images/placeholder-grid-banner.png"),
	BoxArtProvider.LAYOUT.LOGO: preload("res://assets/images/empty-grid-logo.png")
}

# Dictionary of registered boxart providers
var _providers: Dictionary = {}
var _providers_by_priority: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var boxart_local := boxart_local_provider.instantiate()
	add_child(boxart_local)
	get_parent().ready.connect(_on_parent_ready)


# Called when our parent is ready
func _on_parent_ready() -> void:
	# TODO: Load settings and sort by provider priority
	pass


# Returns the boxart of the given kind for the given library item. 
func get_boxart(item: LibraryItem, kind: BoxArtProvider.LAYOUT) -> Texture2D:
	if _providers.is_empty():
		logger.error("No box art providers were found!")
		return null
	
	# Try each provider in order of priority
	for id in _providers_by_priority:
		logger.debug("Trying to load boxart for {0} using provider: {1}".format([item.name, id]))
		var provider: BoxArtProvider = _providers[id]
		var texture: Texture2D = await provider.get_boxart(item, kind)
		if texture == null:
			continue
		return texture
	return null


# Returns the boxart of the given kind for the given library item. If one is not
# found, a placeholder texture will be returned
func get_boxart_or_placeholder(item: LibraryItem, kind: BoxArtProvider.LAYOUT) -> Texture2D:
	var boxart: Texture2D = await get_boxart(item, kind)
	if boxart == null:
		return _placeholder_map[kind]
	return boxart


# Returns a boxart placeholder for the given layout
func get_placeholder(kind:  BoxArtProvider.LAYOUT) -> Texture2D:
	return _placeholder_map[kind]


# Returns the given boxart implementation by id
func get_provider_by_id(id: String) -> BoxArtProvider:
	return _providers[id]


# Returns a list of all registered boxart providers
func get_providers() -> Array:
	return _providers.values()


# Registers the given boxart provider with the boxart manager.
func register_provider(provider: BoxArtProvider) -> void:
	if not _is_valid_provider(provider):
		logger.error("Invalid boxart provider defined! Ensure you have all required properties set: " + ",".join(REQUIRED_FIELDS))
		return
	if provider.provider_id in _providers:
		logger.debug("Provider already registered: " + provider.provider_id)
		return
	_providers[provider.provider_id] = provider
	_providers_by_priority.push_back(provider.provider_id)
	logger.info("Registered boxart provider: " + provider.provider_id)
	provider_registered.emit(provider)


# Unregisters the given boxart provider
func unregister_provider(provider: BoxArtProvider) -> void:
	if not provider.provider_id in _providers:
		logger.warn("BoxArt provider already unregistered")
		return
	_providers.erase(provider.provider_id)
	_providers_by_priority.erase(provider.provider_id)
	logger.info("Unregistered boxart provider: " + provider.provider_id)
	provider_unregistered.emit(provider.provider_id)


# Validates the given provider and returns true if it has the required properties
# set.
func _is_valid_provider(provider: BoxArtProvider) -> bool:
	for field in REQUIRED_FIELDS:
		var data = provider.get(field)
		if data == "":
			return false
	return true

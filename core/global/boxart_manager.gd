@icon("res://assets/icons/image.svg")
extends Resource
class_name BoxArtManager

## Fetch and manage artwork from registered [BoxArtProvider] nodes
## 
## The BoxArtManager is responsible for managing any number of [BoxArtProvider]
## nodes and providing a unified way to fetch box art from multiple sources to 
## any systems that might need them. New box art sources can be created in the 
## core code base or in plugins by implementing/extending the [BoxArtProvider]
## class and adding them to the scene.[br][br]
## 
## With registered box art providers, other systems can request box art from the 
## BoxArtManager, and it will use all available sources to return the best 
## artwork:
##     [codeblock]
##     const BoxArtManager := preload("res://core/global/boxart_manager.tres")
##     ...
##     var boxart := BoxArtManager.get_boxart(library_item, BoxArtProvider.LAYOUT.LOGO)
##     [/codeblock]

const SettingsManager := preload("res://core/global/settings_manager.tres")
const io_thread = preload("res://core/systems/threading/io_thread.tres")

## Fields required to be set by [BoxArtProvider] implementations
const REQUIRED_FIELDS: Array = ["provider_id"]

## Emitted when a boxart provider is added to the scene tree and registers
signal provider_registered(boxart: BoxArtProvider)
## Emitted when a boxart provider is removed from the scene tree
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


func _init() -> void:
	io_thread.start()


## Returns the boxart of the given kind for the given library item. 
func get_boxart(item: LibraryItem, kind: BoxArtProvider.LAYOUT) -> Texture2D:
	return await io_thread.exec(_get_boxart_sync.bind(item, kind))


func _get_boxart_sync(item: LibraryItem, kind: BoxArtProvider.LAYOUT) -> Texture2D:
	if not item:
		return null

	if _providers.is_empty():
		logger.error("No box art providers were found!")
		return null

	# Check to see if the given library item has a provider set
	var provider_id := SettingsManager.get_library_value(item, "boxart_provider", "") as String
	if provider_id != "" and provider_id in _providers:
		var provider: BoxArtProvider = _providers[provider_id]
		var texture: Texture2D = await provider.get_boxart(item, kind)
		return texture
	
	# Try each provider in order of priority
	for id in _providers_by_priority:
		logger.debug("Trying to load boxart for {0} using provider: {1}".format([item.name, id]))
		var provider: BoxArtProvider = _providers[id]
		var texture: Texture2D = await provider.get_boxart(item, kind)
		if texture == null:
			continue
		return texture
	return null


## Returns the boxart of the given kind for the given library item. If one is not
## found, a placeholder texture will be returned
func get_boxart_or_placeholder(item: LibraryItem, kind: BoxArtProvider.LAYOUT) -> Texture2D:
	var boxart: Texture2D = await get_boxart(item, kind)
	if boxart == null:
		return _placeholder_map[kind]
	return boxart


## Returns a boxart placeholder for the given layout
func get_placeholder(kind:  BoxArtProvider.LAYOUT) -> Texture2D:
	return _placeholder_map[kind]


## Returns the given boxart implementation by id
func get_provider_by_id(id: String) -> BoxArtProvider:
	return _providers[id]


## Returns a list of all registered boxart providers
func get_providers() -> Array:
	return _providers.values()


## Returns a list of all registered boxart provider ids
func get_provider_ids() -> Array:
	return _providers.keys()


## Registers the given boxart provider with the boxart manager.
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


## Unregisters the given boxart provider
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

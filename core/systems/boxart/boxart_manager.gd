extends Node
class_name BoxArtManager
@icon("res://assets/icons/image.svg")

const REQUIRED_FIELDS: Array = ["provider_id"]

signal provider_registered(boxart: BoxArtProvider)

# The different layouts of boxart that are supported
enum Layout {
	GRID_PORTRAIT,
	GRID_LANDSCAPE,
	BANNER,
	LOGO,
}

# Map the layouts to different placeholders
const _placeholder_map = {
	Layout.GRID_PORTRAIT: preload("res://assets/images/placeholder-grid-portrait.png"),
	Layout.GRID_LANDSCAPE: preload("res://assets/images/placeholder-grid-landscape.png"),
	Layout.BANNER: preload("res://assets/images/placeholder-grid-banner.png"),
	Layout.LOGO: preload("res://assets/images/empty-grid-logo.png")
}

# Dictionary of registered boxart providers
var _providers: Dictionary = {}
var _providers_by_priority: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var main: Main = get_parent()
	main.ready.connect(_on_parent_ready)


# Called when our parent is ready
func _on_parent_ready() -> void:
	var providers = get_tree().get_nodes_in_group("boxart_provider")
	for provider in providers:
		_register_provider(provider)
	# TODO: Load settings and sort by provider priority


# Returns the boxart of the given kind for the given library item. If 'fallthrough'
# is true, we will keep trying additional providers in order of priority until
# boxart is returned. Optionally a boxart provider id can be given to only use
# a single provider (fallthrough is ignored).
func get_boxart(item: LibraryItem, kind: Layout, fallthrough: bool = true, provider_id: String = "") -> Texture2D:
	if _providers.is_empty():
		push_error("No box art providers were found!")
		return null
	
	# Try each provider in order of priority
	if fallthrough:
		for id in _providers_by_priority:
			var provider: BoxArtProvider = _providers[id]
			var texture: Texture2D = provider.get_boxart(item, kind)
			if texture == null:
				continue
			return texture
		return null
	
	# If no provider was passed, use the first one we find.
	var provider: BoxArtProvider
	if provider_id == "":
		provider = _providers[_providers_by_priority[0]]
	else:
		if not provider_id in _providers:
			push_error("BoxArt Provider {0} was not found!".format([provider_id]))
			return null
		provider = _providers[provider_id]
		
	return provider.get_boxart(item, kind)


# Does the same as 'get_boxart', but is called asyncronously. When a result is
# found, the given callback will get called with the result.
func get_boxart_async(item: LibraryItem, kind: Layout, callback: Callable) -> void:
	if _providers.is_empty():
		push_error("No box art providers were found!")
		callback.call(null)
		return

	# Send the request to all providers
	for id in _providers_by_priority:
		var provider: BoxArtProvider = _providers[id]
		var texture: Texture2D = await provider.get_boxart(item, kind)
		if texture == null:
			continue
		callback.call(texture)
		return
	callback.call(null)


# Returns the boxart of the given kind for the given library item. If 'fallthrough'
# is true, we will keep trying additional providers in order of priority until
# boxart is returned. Optionally a boxart provider id can be given to only use
# a single provider (fallthrough is ignored).
func get_boxart_or_placeholder(item: LibraryItem, kind: Layout, fallthrough: bool = true, provider_id: String = "") -> Texture2D:
	var boxart: Texture2D = get_boxart(item, kind, fallthrough, provider_id)
	if boxart == null:
		return _placeholder_map[kind]
	return boxart


# Does the same as 'get_boxart_or_placeholder', but is called asyncronously. When a result is
# found, the given callback will get called with the result.
func get_boxart_or_placeholder_async(item: LibraryItem, kind: Layout, callback: Callable) -> void:
	get_boxart_async(item, kind, _on_boxart_found.bind(kind, callback))
	

func _on_boxart_found(boxart: Texture2D, kind: int, callback: Callable) -> void:
	if boxart == null:
		callback.call(_placeholder_map[kind])
		return
	callback.call(boxart)


# Returns the given boxart implementation by id
func get_provider_by_id(id: String) -> BoxArtProvider:
	return _providers[id]


# Returns a list of all registered boxart providers
func get_providers() -> Array:
	return _providers.values()


# Registers the given boxart provider with the boxart manager.
func _register_provider(provider: BoxArtProvider) -> void:
	if not _is_valid_provider(provider):
		push_error("Invalid boxart provider defined! Ensure you have all required properties set: ", ",".join(REQUIRED_FIELDS))
		return
	_providers[provider.provider_id] = provider
	_providers_by_priority.push_back(provider.provider_id)
	print("Registered boxart provider: ", provider.provider_id)
	provider_registered.emit(provider)


# Validates the given provider and returns true if it has the required properties
# set.
func _is_valid_provider(provider: BoxArtProvider) -> bool:
	for field in REQUIRED_FIELDS:
		var data = provider.get(field)
		if data == "":
			return false
	return true

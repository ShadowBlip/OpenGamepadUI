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

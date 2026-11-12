extends Resource
class_name MetadataManager

## Fetch and manage metadata from registered [MetadataProvider] nodes
## 
## The MetadataManager is responsible for managing any number of [MetadataProvider]
## nodes and providing a unified way to fetch metadata from multiple sources to 
## any systems that might need them. New metadata sources can be created in the 
## core code base or in plugins by implementing/extending the [MetadataProvider]
## class and adding them to the scene.[br][br]

const settings_manager := preload("res://core/global/settings_manager.tres")

## Fields required to be set by [MetadataProvider] implementations
const REQUIRED_FIELDS: Array = ["provider_id"]

## Emitted when a metadata provider is added to the scene tree and registers
signal provider_registered(provider: MetadataProvider)
## Emitted when a metadata provider is removed from the scene tree
signal provider_unregistered(provider_id: String)

var logger := Log.get_logger("MetadataManager")

# Dictionary of registered metadata providers
var _providers: Dictionary[String, MetadataProvider] = {}
var _providers_by_priority: Array[String] = []


## Returns the boxart of the given kind for the given library item. 
func get_summary(item: LibraryItem) -> String:
	return await _get_summary_sync(item)


func _get_summary_sync(item: LibraryItem) -> String:
	if not item:
		return ""

	if _providers.is_empty():
		logger.error("No metadata providers were found!")
		return ""

	# Check to see if the given library item has a provider set
	var provider_id := settings_manager.get_library_value(item, "metadata_provider", "") as String
	if provider_id != "" and provider_id in _providers:
		var provider := _providers[provider_id]
		@warning_ignore("redundant_await")
		var summary := await provider.get_summary(item)
		return summary
	
	# Try each provider in order of priority
	for id in _providers_by_priority:
		logger.debug("Trying to load summary for {0} using provider: {1}".format([item.name, id]))
		var provider := _providers[id]
		@warning_ignore("redundant_await")
		var summary := await provider.get_summary(item)
		if summary.is_empty():
			continue
		return summary

	return ""

## Returns the given metadata implementation by id
func get_provider_by_id(id: String) -> MetadataProvider:
	return _providers[id]


## Returns a list of all registered metadata providers
func get_providers() -> Array[MetadataProvider]:
	return _providers.values()


## Returns a list of all registered metadata provider ids
func get_provider_ids() -> Array[String]:
	return _providers.keys()


## Registers the given metadata provider with the metadata manager.
func register_provider(provider: MetadataProvider) -> void:
	if not _is_valid_provider(provider):
		logger.error("Invalid metadata provider defined! Ensure you have all required properties set: " + ",".join(REQUIRED_FIELDS))
		return
	if provider.provider_id in _providers:
		logger.debug("Provider already registered: " + provider.provider_id)
		return
	_providers[provider.provider_id] = provider
	_providers_by_priority.push_back(provider.provider_id)
	logger.info("Registered metadata provider: " + provider.provider_id)
	provider_registered.emit(provider)


## Unregisters the given metadata provider
func unregister_provider(provider: MetadataProvider) -> void:
	if not provider.provider_id in _providers:
		logger.warn("Metadata provider already unregistered")
		return
	_providers.erase(provider.provider_id)
	_providers_by_priority.erase(provider.provider_id)
	logger.info("Unregistered metadata provider: " + provider.provider_id)
	provider_unregistered.emit(provider.provider_id)


# Validates the given provider and returns true if it has the required properties
# set.
func _is_valid_provider(provider: MetadataProvider) -> bool:
	for field in REQUIRED_FIELDS:
		@warning_ignore("unsafe_call_argument")
		var data = provider.get(field)
		if data == "":
			return false
	return true

@icon("res://assets/icons/package.svg")
extends Resource
class_name LibraryItem

## LibraryItem is a high-level structure that contains data about a game.
##
## A LibraryItem is a single game title that may have one or more library 
## providers. It contains an array of [LibraryLaunchItem] resources that can 
## tell us how to launch a game.

## Is emitted when the [LibraryManager] adds this item to the library
signal added_to_library
## Is emitted when the [LibraryManager] removes this item from the library
signal removed_from_library
## Emitted when a user has updated the boxart for this library item
signal boxart_updated
## Emitted when the [InstallManager] has installed this library item
signal installed(launch_item: LibraryLaunchItem)
## Emitted when the [InstallManager] has uninstalled this library item
signal uninstalled(launch_item: LibraryLaunchItem)
## Emitted when the [InstallManager] has updated this library item
signal upgraded(launch_item: LibraryLaunchItem)

## The unique ID of the library item
@export var _id: String
## Name of the game
@export var name: String
## An array of [LibraryLaunchItem] resources that this game supports
@export var launch_items: Array[LibraryLaunchItem] = []
## An array of tags associated with this game
@export var tags: PackedStringArray
## An array of categories the game belongs to
@export var categories: PackedStringArray


## Creates a new library item from the given library launch item
static func new_from_launch_item(launch_item: LibraryLaunchItem) -> LibraryItem:
	var item: LibraryItem = LibraryItem.new()
	item.name = launch_item.name
	item.tags = launch_item.tags
	item.categories = launch_item.categories
	return item

## Returns the library launch item for the given provider. Returns null if the 
## given provider doesn't manage this game.
func get_launch_item(provider_id: String) -> LibraryLaunchItem:
	for i in launch_items:
		var launch_item: LibraryLaunchItem = i
		if launch_item._provider_id == provider_id:
			return launch_item
	return null


## Returns true if the [LibraryItem] has a [LibraryLaunchItem] from the given provider
func has_launch_item(provider_id: String) -> bool:
	return get_launch_item(provider_id) != null


## Removes the [LibraryLaunchItem] associated with the given launch provider.
func erase_launch_item(provider_id: String) -> void:
	var to_erase: Array[LibraryLaunchItem] = []
	for launch_item in launch_items:
		if launch_item._provider_id == provider_id:
			to_erase.append(launch_item)
	
	for item in to_erase:
		launch_items.erase(item)


## Returns true if at least one library provider has this item installed.
func is_installed() -> bool:
	for i in launch_items:
		var launch_item: LibraryLaunchItem = i
		if launch_item.installed:
			return true
	return false

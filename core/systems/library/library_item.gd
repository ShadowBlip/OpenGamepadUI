# LibraryItem is a high-level structure that contains data about a game.
extends Resource
class_name LibraryItem
@icon("res://assets/icons/package.svg")

@export var _id: String
@export var name: String
@export var launch_items: Array = []
@export var tags: PackedStringArray
@export var categories: PackedStringArray


# Creates a new library item from the given library launch item
static func new_from_launch_item(launch_item: LibraryLaunchItem) -> LibraryItem:
	var item: LibraryItem = LibraryItem.new()
	item.name = launch_item.name
	item.tags = launch_item.tags
	item.categories = launch_item.categories
	return item


func is_installed() -> bool:
	for i in launch_items:
		var launch_item: LibraryLaunchItem = i
		if launch_item.installed:
			return true
	return false

#  shortcutId: 123
#  name: Fortnite
#  command: steam
#  args: []
#  provider: steam
#  providerAppId: 1234
#  tags: []
#  categories: []

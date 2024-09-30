@icon("res://assets/icons/box.svg")
extends Resource
class_name LibraryLaunchItem

## LibraryLaunchItem is a library provider-specific structure that describes how to launch a game.
##
## A LibraryLaunchItem is a provider-specific resource that describes a library
## item and how to launch it. It is always tied to a [LibraryItem].

signal added_to_library
signal removed_from_library

@export var _id: String
@export var _provider_id: String
@export var provider_app_id: String
@export var name: String
@export var command: String
@export var args: PackedStringArray
@export var env: Dictionary
@export var cwd: String
@export var tags: PackedStringArray
@export var categories: PackedStringArray
@export var installed: bool
@export var hidden: bool
@export var metadata: Dictionary


# Returns the given launch item as a dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"_id": _id,
		"_provider_id": _provider_id,
		"provider_app_id": provider_app_id,
		"name": name,
		"command": command,
		"args": args,
		"env": env,
		"cwd": cwd,
		"tags": tags,
		"categories": categories,
		"installed": installed,
		"hidden": hidden,
		"metadata": metadata,
	}


# Returns a new LibraryLaunchItem from the given dictionary
static func from_dict(d: Dictionary) -> LibraryLaunchItem:
	var item := LibraryLaunchItem.new()
	item._id = d["_id"]
	item._provider_id = d["_provider_id"]
	item.provider_app_id = d["provider_app_id"]
	item.name = d["name"]
	item.command = d["command"]
	item.args = d["args"]
	item.tags = d["tags"]
	item.categories = d["categories"]
	item.installed = d["installed"]
	if "env" in d:
		item.env = d["env"]
	if "cwd" in d:
		item.cwd = d["cwd"]
	if "hidden" in d:
		item.hidden = d["hidden"]
	if "metadata" in d:
		item.metadata = d["metadata"]
	return item


## Returns a numerical app ID associated with the launch item
func get_app_id() -> int:
	# If this launch item launches a Steam game, use the Steam app id instead
	for arg in self.args:
		if not arg.contains("steam://rungameid/"):
			continue
		var parts := arg.split("/", false)
		if parts.is_empty():
			continue
		var id := parts[-1] as String
		if not id.is_valid_int():
			continue
		return int(id)

	# In all other cases, use the hash of the app name for its app id
	var app_id := hash(self.name)

	return app_id

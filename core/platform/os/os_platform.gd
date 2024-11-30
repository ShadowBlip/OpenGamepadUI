@icon("res://assets/editor-icons/linux.svg")
extends PlatformProvider
class_name OSPlatform

@export_category("Images")
@export var logo: Texture2D ## Logo of the OS


## If the OS requires running regular binaries through a compatibility tool,
## this method should return the given command/args prepended with the compatibility
## tool to use.
func get_binary_compatibility_cmd(cmd: String, args: PackedStringArray) -> Array[String]:
	var result: Array[String] = []
	return result

extends RefCounted
class_name Xdg

## Fallback system data directory if XDG cannot be used
const XDG_DATA_DIR_FALLBACK := "/usr/share"


## Return a list of system data paths in load preference order.
static func get_data_dirs() -> PackedStringArray:
	if not OS.has_environment("XDG_DATA_DIRS"):
		return PackedStringArray()
	var dirs := OS.get_environment("XDG_DATA_DIRS")

	return dirs.split(":", false)


## Return the XDG system data path with the given relative path.
## For example, using `Xdg.with_system_path("hwdata")` will return
## "/usr/share/hwdata". If XDG is unable to determine the path,
## the fallback prefix of "/usr/share" will be used.
static func with_system_path(path: String) -> String:
	var data_dirs := get_data_dirs()
	for dir in data_dirs:
		var full_path := dir.path_join(path)
		if DirAccess.dir_exists_absolute(full_path) or FileAccess.file_exists(full_path):
			return full_path
	
	return XDG_DATA_DIR_FALLBACK.path_join(path)

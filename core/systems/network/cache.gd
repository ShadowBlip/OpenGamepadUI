extends Object
class_name Cache

const CHUNK_SIZE = 256
const IMAGE_EXTS = ["png", "jpg", "jpeg", "bmp"]

# Caching flags to determine caching behavior for systems using caching. This is
# intended to be used for binary flags to determine caching. So you can use
# 'CacheManager.FLAGS.LOAD|CacheManager.FLAGS.SAVE' to enable loading items from
# cache as well as saving.
enum FLAGS {
	NONE,
	LOAD,
	SAVE,
}


# Deletes the given cache item from the cache
static func delete(folder: String, key: String) -> int:
	var hash := key.sha256_text()
	
	# Build the cache directory to look in
	var base_dir: String = ProjectSettings.get_setting("OpenGamepadUI/cache/directory")
	var cache_dir := "/".join([base_dir, folder])
	var cached_file_path := "/".join([cache_dir, hash])
	
	# Delete the cache file
	return DirAccess.remove_absolute(cached_file_path)


# Saves the given PackedByteArray to the given folder cache key
static func save_data(folder: String, key: String, data: PackedByteArray, flush: bool = false) -> int:
	var hash := key.sha256_text()
	
	# Build the cache directory to look in
	var base_dir: String = ProjectSettings.get_setting("OpenGamepadUI/cache/directory")
	var cache_dir := "/".join([base_dir, folder])
	var cached_file_path := "/".join([cache_dir, hash])
	_ensure_cache_dir(folder)
	
	# Save the data
	var file := FileAccess.open(cached_file_path, FileAccess.WRITE_READ)
	file.store_buffer(data)
	if flush:
		file.flush()
	
	return OK


# Saves the given Texture2D to the given folder and cache key
static func save_image(folder: String, key: String, texture: Texture2D, image_type: String = "") -> int:
	var hash := key.sha256_text()
	# If no image type was passed, try to determine it from the key
	var ext := image_type
	if ext == "":
		ext = key.split(".")[-1]
		
	# Check if this is a valid image type
	ext = ext.to_lower()
	if not ext in IMAGE_EXTS:
		var logger := Log.get_logger("Cache")
		logger.error("The given key does not appear to be an image. If it is, pass the image_type.")
		return ERR_CANT_CREATE

	# Build the cache directory to look in
	var base_dir: String = ProjectSettings.get_setting("OpenGamepadUI/cache/directory")
	var cache_dir := "/".join([base_dir, folder])
	var cached_file_path := "/".join([cache_dir, hash])
	_ensure_cache_dir(folder)

	# Get the image from the texture
	var err := ERR_CANT_CREATE
	var image := texture.get_image()
	match ext:
		"png":
			err = image.save_png(cached_file_path)
		"jpg", "jpeg":
			err = image.save_jpg(cached_file_path)
	return err


# Returns the given cached data as a PackedByteArray. Returns null if the
# given key is not cached.
static func get_data(folder: String, key: String) -> Variant:
	# Check if the item is actually cached
	var hash := key.sha256_text()
	if not _is_cached_hash(folder, hash):
		return null
	
	# Build the cache directory to look in
	var base_dir: String = ProjectSettings.get_setting("OpenGamepadUI/cache/directory")
	var cache_dir := "/".join([base_dir, folder])
	var cached_file_path := "/".join([cache_dir, hash])
	
	# Open our cache file
	var file := FileAccess.open(cached_file_path, FileAccess.READ)
	var buffer := PackedByteArray()
	while not file.eof_reached():
		buffer.append_array(file.get_buffer(CHUNK_SIZE))
		
	
	return buffer
	

# Returns the given cache item as a Texture2D. Returns null if the given
# key is not cached or is not an image.
static func get_image(folder: String, key: String, image_type: String = "") -> Texture2D:
	# If no image type was passed, try to determine it from the key
	var ext := image_type
	if ext == "":
		ext = key.split(".")[-1]
		
	# Check if this is a valid image type
	ext = ext.to_lower()
	if not ext in IMAGE_EXTS:
		var logger := Log.get_logger("Cache")
		logger.error("The given key does not appear to be an image. If it is, pass the image_type.")
		return null
	
	# Fetch the image bytes
	var data = get_data(folder, key)
	if data == null:
		return null
	
	# Build an image texture from the bytes
	var err: int = ERR_CANT_CREATE
	var image: Image = Image.new()
	match ext:
		"png":
			err = image.load_png_from_buffer(data)
		"bmp":
			err = image.load_bmp_from_buffer(data)
		"jpg", "jpeg":
			err = image.load_jpg_from_buffer(data)
	if err != OK:
		var logger := Log.get_logger("Cache")
		logger.error("Unable to load image from cache")
		return null
	
	return ImageTexture.create_from_image(image)
	
	
# Returns whether or not the given item in the given folder is cached.
static func is_cached(folder: String, key: String) -> bool:
	var hash := key.sha256_text()
	return _is_cached_hash(folder, hash)


# Checks if the given hash is in the given cache folder
static func _is_cached_hash(folder: String, hash: String) -> bool:
	var base_dir: String = ProjectSettings.get_setting("OpenGamepadUI/cache/directory")
	var cache_dir := "/".join([base_dir, folder])
	var cached_file_path := "/".join([cache_dir, hash])
	if FileAccess.file_exists(cached_file_path):
		return true
	return false


# Ensures the given cache folder is created
static func _ensure_cache_dir(folder: String) -> void:
	var base_dir: String = ProjectSettings.get_setting("OpenGamepadUI/cache/directory")
	var cache_dir := "/".join([base_dir, folder])
	DirAccess.make_dir_recursive_absolute(cache_dir)

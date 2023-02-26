extends Node
class_name HTTPImageFetcher

const CACHE_DIR = "images"

var logger := Log.get_logger("HTTPImageFetcher")


# Fetches the image from the given URL and returns it as a Texture2D. Returns
# null if fetching the image failed. Optionally caching flags can be passed to
# determine caching behavior.
# Example:
#   fetch(url, Cache.FLAGS.LOAD|Cache.FLAGS.SAVE)
func fetch(url: String, caching_flags: int = Cache.FLAGS.LOAD|Cache.FLAGS.SAVE) -> Texture2D:
	# Check to see if the given image is already cached
	if caching_flags & Cache.FLAGS.LOAD and Cache.is_cached(CACHE_DIR, url):
		var texture = Cache.get_image(CACHE_DIR, url)
		if texture != null:
			return texture

	# Build the request
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request(url) != OK:
		logger.debug("Error making http request for image: " + url)
		_remove(http)
		return null

	# Wait for the request signal to complete
	# result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
	var args: Array = await http.request_completed
	var result: int = args[0]
	var response_code: int = args[1]
	var headers: PackedStringArray = args[2]
	var body: PackedByteArray = args[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		logger.debug("Image couldn't be downloaded: " + url)
		_remove(http)
		return null

	# Load the image based on extension
	var ext = url.split(".")[-1]
	var image = Image.new()
	var error: int = ERR_INVALID_DATA
	if ext == "jpg" or ext == "jpeg":
		error = image.load_jpg_from_buffer(body)
	elif ext == "png":
		error = image.load_png_from_buffer(body)
	if error != OK:
		logger.debug("Couldn't load the image: " + url)
		_remove(http)
		return null

	# Load the texture
	var texture: Texture2D = ImageTexture.create_from_image(image)
	_remove(http)
	
	# Cache the result
	if caching_flags & Cache.FLAGS.SAVE:
		Cache.save_image(CACHE_DIR, url, texture)

	return texture

func _remove(child: Node):
	remove_child(child)
	child.queue_free()

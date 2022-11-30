extends BoxArtProvider

const _boxart_dir = "user://boxart/steam"
const _supported_ext = [".jpg", ".png", ".jpeg"]

@export var use_caching: bool = true

# Maps the layout to a file suffix for caching
var layout_map: Dictionary = {
	BoxArtManager.Layout.GRID_PORTRAIT: "-portrait",
	BoxArtManager.Layout.GRID_LANDSCAPE: "-landscape",
	BoxArtManager.Layout.BANNER: "-banner",
	BoxArtManager.Layout.LOGO: "-logo",
}

# Maps the layout to the Steam CDN url
var layout_url_map: Dictionary = {
	BoxArtManager.Layout.GRID_PORTRAIT: "https://steamcdn-a.akamaihd.net/steam/apps/{0}/library_600x900.jpg",
	BoxArtManager.Layout.GRID_LANDSCAPE: "https://steamcdn-a.akamaihd.net/steam/apps/{0}/header.jpg",
	BoxArtManager.Layout.BANNER: "https://steamcdn-a.akamaihd.net/steam/apps/{0}/library_hero.jpg",
	BoxArtManager.Layout.LOGO: "https://steamcdn-a.akamaihd.net/steam/apps/{0}/logo.png",
}

func _init() -> void:
	# Create the data directory if it doesn't exist
	DirAccess.make_dir_recursive_absolute(_boxart_dir)
	provider_id = "steam"


func _ready() -> void:
	super()
	print("Steam BoxArt provider loaded")


# Looks for boxart in the local user directory based on the app name
func get_boxart(item: LibraryItem, kind: int) -> Texture2D:
	if not kind in layout_map:
		push_error("Unsupported boxart layout: ", kind)
		return null
		
	# Look for a Steam App ID in the library item
	var steamAppID: String = ""
	for l in item.launch_items:
		var launch_item: LibraryLaunchItem = l
		if launch_item._provider_id == "steam":
			steamAppID = launch_item.provider_app_id
	if steamAppID == "":
		print("No Steam App ID found in library item")
		return null
		
	# See if the image is already cached
	if use_caching:
		var cached: Texture2D = _get_cached_boxart(steamAppID, kind)
		if cached != null:
			return cached
	
	# Try to fetch the artwork
	print("Fetching steam box art for: ", item.name)
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	var url: String = layout_url_map[kind].format([steamAppID])
	if http_request.request(url) != OK:
		push_error("Error making http request for images")
		_remove(http_request)
		return null
	
	# Wait for the request signal to complete
	# result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
	var args: Array = await http_request.request_completed
	var result: int = args[0]
	var response_code: int = args[1]
	var headers: PackedStringArray = args[2]
	var body: PackedByteArray = args[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded")
		_remove(http_request)
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
		push_error("Couldn't load the image.")
		_remove(http_request)
		return null
	
	# Cache the result
	if use_caching:
		var cache_file: String = "/".join([_boxart_dir, steamAppID + layout_map[kind] + "." + ext])
		if ext == "jpg" or ext == "jpeg":
			image.save_jpg(cache_file)
		elif ext == "png":
			image.save_png(cache_file)
		
	# Load the texture
	var texture: Texture2D = ImageTexture.create_from_image(image)
	_remove(http_request)
	
	return texture


func _get_cached_boxart(appID: String, kind: int) -> Texture2D:
	var name: String = appID + layout_map[kind]
	for ext in _supported_ext:
		var path: String = "/".join([_boxart_dir, name + ext])
		print("Checking path '{0}' for cached artwork".format([path]))
		if not FileAccess.file_exists(path):
			continue
		var image: Image = Image.new()
		if image.load(path) != OK:
			push_error("Unable to load artwork at " + path)
			return null
		var texture: ImageTexture = ImageTexture.create_from_image(image)
		print("Found cached artwork")
		return texture
		
	return null


func _remove(child: Node):
	remove_child(child)
	child.queue_free()

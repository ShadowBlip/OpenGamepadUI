extends BoxArtProvider

const _boxart_dir = "user://boxart/local"
const _supported_ext = [".png", ".jpg", ".jpeg"]

# Maps the layout to a file suffix
var layout_map: Dictionary = {
	LAYOUT.GRID_PORTRAIT: "-portrait",
	LAYOUT.GRID_LANDSCAPE: "-landscape",
	LAYOUT.BANNER: "-banner",
	LAYOUT.LOGO: "-logo",
}


func _init() -> void:
	super()
	# Create the data directory if it doesn't exist
	DirAccess.make_dir_recursive_absolute(_boxart_dir)
	provider_id = "local"
	logger_name = "BoxArtLocal"


func _ready() -> void:
	logger.info("Local BoxArt provider loaded")


# Looks for boxart in the local user directory based on the app name
func get_boxart(item: LibraryItem, kind: LAYOUT) -> Texture2D:
	logger.debug("Fetching box art for: " + item.name)
	if not kind in layout_map:
		logger.error("Unsupported boxart layout: {0}".format([kind]))
		return null
		
	var name: String = item.name + layout_map[kind]
	for ext in _supported_ext:
		var path: String = "/".join([_boxart_dir, name + ext])
		logger.debug("Checking path '{0}' for local artwork".format([path]))
		if not FileAccess.file_exists(path):
			continue
		var image: Image = Image.new()
		if image.load(path) != OK:
			logger.error("Unable to load artwork at " + path)
			return null
		var texture: ImageTexture = ImageTexture.create_from_image(image)
		return texture
	return null

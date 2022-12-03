extends Control

var logger : Log.Logger
@onready var plugin_name_label := $MarginContainer/VBoxContainer/PluginNameLabel
@onready var plugin_texture := $MarginContainer/VBoxContainer/HBoxContainer/TextureRect
@onready var author_label := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AuthorLabel
@onready var summary_label := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SummaryLabel
@onready var install_button := $MarginContainer/HBoxContainer/InstallButton

var download_url: String 
var project_url: String
var sha256: String
var plugin_id: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	install_button.button_up.connect(_on_install_button)

func set_logger(name: String) -> void:
	logger = Log.get_logger(name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_install_button() -> void:
	# Build the request
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request(download_url) != OK:
		logger.error("Error making http request for plugin package: " + download_url)
		_remove(http)
		return

	# Wait for the request signal to complete
	# result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
	var args: Array = await http.request_completed
	var result: int = args[0]
	var response_code: int = args[1]
	var headers: PackedStringArray = args[2]
	var body: PackedByteArray = args[3]
	_remove(http)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		logger.error("Plugin couldn't be downloaded: " + download_url)
		return
		
	# Now we have the body ;)
	var ctx = HashingContext.new()
	
	# Start a SHA-256 context.
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(body)
	
	# Get the computed hash.
	var res = ctx.finish()
	
	# Print the result as hex string and array.
	if res.hex_encode() != sha256:
		logger.error("sha256 hash does not match for the downloaded plugin archive. Contact the plugin maintainer.")
		return
	
	# Install the plugin.
	var plugin_dir : String = ProjectSettings.get("OpenGamepadUI/plugin/directory")
	DirAccess.make_dir_recursive_absolute(plugin_dir)
	var file := FileAccess.open("/".join([plugin_dir, plugin_id + ".zip"]), FileAccess.WRITE_READ)
	file.store_buffer(body)
	
func _remove(child: Node):
	remove_child(child)
	child.queue_free()

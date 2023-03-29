extends Node

const update_pack := "user://updates/update.pck"

var logger := Log.get_logger("Entrypoint")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().get_root().transparent_bg = true
	var args := OS.get_cmdline_args()
	
	# Apply any update packs
	# TODO: Add package signing/checking before loading update packs?
	if FileAccess.file_exists(update_pack):
		logger.info("Update pack found. Applying update.")
		if ProjectSettings.load_resource_pack(update_pack):
			logger.info("Update pack loaded successfully")
		else:
			logger.warn("Failed to load update pack")

	# Launch only-qam mode
	if "--qam-only" in args or "--only-qam" in args:
		get_tree().change_scene_to_file("res://core/only_qam.tscn")
		return

	# Launch the main interface
	get_tree().change_scene_to_file("res://core/main.tscn")

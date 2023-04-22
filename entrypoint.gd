extends Node

const update_pack_file := "user://updates/update.pck"
const signature_file := "user://updates/update.pck.sig"

var PackageVerifier := preload("res://core/global/package_verifier.tres") as PackageVerifier
var args := OS.get_cmdline_args()
var logger := Log.get_logger("Entrypoint")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().get_root().transparent_bg = true
	var version := load("res://core/global/version.tres") as Version
	print("OpenGamepadUI v", version.core)
	
	# Apply any update packs
	_apply_update_packs()

	# Launch only-qam mode
	if "--qam-only" in args or "--only-qam" in args:
		get_tree().change_scene_to_file("res://core/only_qam_main.tscn")
		return

	# Launch the main interface
	get_tree().change_scene_to_file("res://core/ui/cardui/cardui.tscn")
	#get_tree().change_scene_to_file("res://core/main.tscn")
	

# Applies any update packs to load newer scripts and resources
# TODO: Verify that pack version is not older than current version before
# loading
func _apply_update_packs() -> void:
	if not FileAccess.file_exists(update_pack_file):
		return
	logger.info("Update pack was found.")
	
	# Validate the signature on the update pack.
	if "--skip-verify-packages" in args:
		logger.warn("Skipping validation of update pack. This could be dangerous!")
	else:
		if not FileAccess.file_exists(signature_file):
			logger.warn("Unable to find signature file for update pack. Not loading update pack.")
			return
		var signature := FileAccess.get_file_as_bytes(signature_file)
		if not PackageVerifier.file_has_valid_signature(update_pack_file, signature):
			logger.warn("Update pack does not have a valid signature! Not loading update pack.")
			return
	
	# Load the update pack
	if ProjectSettings.load_resource_pack(update_pack_file):
		logger.info("Update pack loaded successfully")
		var version := ResourceLoader.load("res://core/global/version.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as Version
		version.take_over_path("res://core/global/version.tres")
		print("OpenGamepadUI Update Pack v", version.core)
	else:
		logger.warn("Failed to load update pack")

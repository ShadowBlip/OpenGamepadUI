extends Node

const updates_path := "user://updates"
const update_pack_file := "user://updates/update.zip"
const update_pack_entrypoint := "user://updates/opengamepad-ui.x86_64"

var PackageVerifier := preload("res://core/global/package_verifier.tres") as PackageVerifier
var args := OS.get_cmdline_args()
var logger := Log.get_logger("Entrypoint")

func _init() -> void:
	var version := load("res://core/global/version.tres") as Version
	print("OpenGamepadUI v", version.core)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var window := get_viewport()
	window.transparent_bg = true
	
	# Apply any update packs
	if not "--skip-update-pack" in args:
		_apply_update_packs()
	
	# Launch the main interface
	get_tree().change_scene_to_file("res://core/main.tscn")
	

# Applies any update packs to load newer scripts and resources
# TODO: Verify that pack version is not older than current version before
# loading
func _apply_update_packs() -> void:
	if not FileAccess.file_exists(update_pack_file):
		return
	logger.info("Update pack was found.")
	
	# Check if we should validate update archive signatures
	var verify_signatures := not "--skip-verify-packages" in args
	if not verify_signatures:
		logger.warn("Skipping validation of update pack. This could be dangerous!")

	# Read the metadata from the update zip
	var reader := ZIPReader.new()
	if reader.open(update_pack_file) != OK:
		logger.warn("Unable to read update pack file. Not loading update pack.")
		return
	var metadata := reader.read_file("metadata.json")
	if metadata.size() == 0:
		logger.warn("Unable to read metadata.json from update pack.")
		return
	
	# Parse the metadata from the zip file
	var parsed_metadata = JSON.parse_string(metadata.get_string_from_ascii())
	if not parsed_metadata is Dictionary:
		logger.warn("Unable to parse metadata.json")
		return
	if not "version" in parsed_metadata:
		logger.warn("No version found in metadata.json")
		return
	if not "files" in parsed_metadata:
		logger.warn("No files list found in metadata.json")
		return
	logger.info("Update pack version: " + parsed_metadata["version"])
	
	# Check if the update pack is a newer version than our version
	var version := load("res://core/global/version.tres") as Version
	if not SemanticVersion.is_greater_or_equal(version.core, parsed_metadata["version"]):
		logger.info("Update pack version is older than base version")
		return
	
	# Validate and extract each file in the update pack
	var files := parsed_metadata["files"] as Dictionary
	for filename in files.keys():
		var file_data := reader.read_file(filename)
		var hash := files[filename]["hash"] as String
		var sig_b64 := files[filename]["signature"] as String
		var sig := Marshalls.base64_to_raw(sig_b64)

		# Validate the file signatures
		if verify_signatures:
			if not PackageVerifier.has_valid_signature(file_data, sig):
				logger.warn("File " + filename + " in update.zip does not have a valid signature. Not loading update pack.")
				return
		
		# Validate the hash defined in the metadata
		if PackageVerifier.get_hash_string(file_data) != hash:
			logger.warn("File " + filename + " in update.zip does not have a valid hash. Not loading update pack.")
			return

		# Check to see if this file is already extracted
		var extracted_path := "/".join([updates_path, filename])
		if FileAccess.file_exists(extracted_path):
			logger.debug("File already exists: " + extracted_path)
			var extracted_hash := PackageVerifier.get_file_hash_string(extracted_path)
			if extracted_hash == hash:
				logger.debug("File hash matches, skipping")
				continue
	
		# Write the extracted file from the update pack
		var extracted_file := FileAccess.open(extracted_path, FileAccess.WRITE_READ)
		extracted_file.store_buffer(file_data)
		extracted_file.flush()
		extracted_file.close()
		
		# Set execute permissions
		if filename == "opengamepad-ui.x86_64":
			var file_path := ProjectSettings.globalize_path(extracted_path)
			if OS.execute("chmod", ["+x", file_path]) != OK:
				logger.warn("Failed to set execute permissions. Not loading update pack")
				return

	# Launch the update pack executable and exit
	var update_bin := ProjectSettings.globalize_path(update_pack_entrypoint)
	var update_args := PackedStringArray([update_bin])
	update_args.append_array(OS.get_cmdline_args())
	update_args.append("--skip-update-pack")
	logger.info("Launching update pack: " + " ".join(update_args))
	var code := OS.execute("exec", update_args)
	logger.info("Child exited")
	get_tree().quit(code)

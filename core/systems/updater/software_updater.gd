@icon("res://assets/editor-icons/document-update.svg")
extends Node
class_name SoftwareUpdater

signal update_available(available: bool)
signal update_installed(status: int)

var Version := preload("res://core/global/version.tres") as Version
var PackageVerifier := preload("res://core/global/package_verifier.tres") as PackageVerifier
var update_pack_url := ""
var logger := Log.get_logger("SoftwareUpdater", Log.LEVEL.INFO)

@export var github_project := "ShadowBlip/OpenGamepadUI"
@export var update_filename := "update.zip"
@export var update_hash_filename := "update.zip.sha256.txt"
@export var update_folder := "user://updates"

@onready var github_client := $GitHubClient as GitHubClient


## Checks to see if there is a newer version of OpenGamepadUI available.
func check_for_updates() -> void:
	logger.info("Checking for OpenGamepadUI updates...")
	# Fetch the latest release from GitHub
	var response = await github_client.get_releases(github_project, 1)
	if response == null:
		logger.info("Unable to check for software updates")
		update_available.emit(false)
		return
	var releases := response as Array
	if releases.size() == 0:
		update_available.emit(false)
		return
	var latest_release := releases[0] as Dictionary
	if not "tag_name" in latest_release:
		logger.info("No tag name in release")
		update_available.emit(false)
		return
	var tag := latest_release["tag_name"] as String
	tag = tag.replace("v", "")
	
	# Check if the release is newer than the current one.
	if not SemanticVersion.is_greater(Version.core, tag):
		logger.debug("Latest release " + tag + " is not newer than installed: " + Version.core)
		update_available.emit(false)
		return
	
	# Look for the update pack in the release assets
	if not "assets" in latest_release:
		logger.info("No assets found in release")
		update_available.emit(false)
		return
	var assets := latest_release["assets"] as Array
	
	# Look for the download url for the pack itself
	update_pack_url = ""
	for asset in assets:
		if not "name" in asset:
			continue
		if not "browser_download_url" in asset:
			continue
		if asset["name"] == update_filename:
			update_pack_url = asset["browser_download_url"]
	
	if update_pack_url == "":
		logger.info("Unable to find update pack in release assets")
		update_available.emit(false)
		return
	
	update_available.emit(true)


## Downloads and installs the given update
func install_update(download_url: String) -> void:
	# Download the update pack
	var update_data := await _download_file(download_url)
	if update_data.size() == 0:
		logger.info("Failed to download update pack")
		update_installed.emit(FAILED)
		return

	# Save the update to the update folder
	DirAccess.make_dir_recursive_absolute(update_folder)
	var update_path := "/".join([update_folder, update_filename])
	var update_file := FileAccess.open(update_path, FileAccess.WRITE)
	update_file.store_buffer(update_data)
	update_file.close()

	update_installed.emit(OK)


## Download the given file and return its data as a PackedByteArray. Returns
## an empty array if file could not be downloaded.
func _download_file(download_url: String) -> PackedByteArray:
	# Build the request
	var http: HTTPRequest = HTTPRequest.new()
	add_child.call_deferred(http)
	await http.ready
	if http.request(download_url) != OK:
		logger.info("Error downloading file: " + download_url)
		http.queue_free()
		return PackedByteArray()

	# Wait for the request signal to complete
	# result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
	var args: Array = await http.request_completed
	var result: int = args[0]
	var response_code: int = args[1]
	var headers: PackedStringArray = args[2]
	var body: PackedByteArray = args[3]
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS:
		logger.info("File couldn't be downloaded: " + download_url)
		update_installed.emit(FAILED)
		return PackedByteArray()
	
	return body

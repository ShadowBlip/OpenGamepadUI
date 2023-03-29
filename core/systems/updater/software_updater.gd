extends Node
class_name SoftwareUpdater

signal update_available

var Version := preload("res://core/global/version.tres") as Version
var update_pack_url := ""
var logger := Log.get_logger("SoftwareUpdater")

@export var github_project := "ShadowBlip/OpenGamepadUI"

@onready var github_client := $GitHubClient as GitHubClient


## Checks to see if there is a newer version of OpenGamepadUI available.
func check_for_updates() -> void:
	# Fetch the latest release from GitHub
	var response = await github_client.get_releases(github_project, 1)
	if response == null:
		logger.info("Unable to check for software updates")
		return
	var releases := response as Array[Dictionary]
	if releases.size() == 0:
		return
	var latest_release := releases[0]
	if not "tag_name" in latest_release:
		logger.info("No tag name in release")
		return
	var tag := latest_release["tag_name"] as String
	tag = tag.replace("v", "")
	
	# Check if the release is newer than the current one.
	if not _is_greater_version(Version.core, tag):
		logger.debug("Latest release " + tag + " is not newer than installed: " + Version.core)
		return
	
	# Look for the update pack in the release assets
	if not "assets" in latest_release:
		logger.info("No assets found in release")
		return
	var assets := latest_release["assets"] as Array[Dictionary]
	
	update_pack_url = ""
	for asset in assets:
		if not "name" in asset:
			continue
		if not "browser_download_url" in asset:
			continue
		if asset["name"] == "update.pck":
			update_pack_url = asset["browser_download_url"]
	
	if update_pack_url == "":
		logger.info("Unable to find update.pck in release assets")
		return
	
	update_available.emit()


# Returns whether or not the given semantic version string is greater than 
# the target semantic version string.  
func _is_greater_version(version: String, target: String) -> bool:
	var version_list := version.split(".")
	var target_list := target.split(".")
	
	# Ensure the given versions are valid semver
	if not _is_valid_semver(version_list) or not _is_valid_semver(target_list):
		return false
	
	# Compare major versions: X.x.x
	if target_list[0] > version_list[0]:
		return true
	var matches_major := false
	if target_list[0] == version_list[0]:
		matches_major = true
	
	# Compare minor versions: x.X.x
	if matches_major and target_list[1] > version_list[1]:
		return true
	var matches_minor := false
	if target_list[1] == version_list[1]:
		matches_minor = true
	
	# Compare patch versions: x.x.X
	if matches_minor and target_list[2] > version_list[2]:
		return true
		
	return false


# Returns whether or not the given version array is a valid semver
func _is_valid_semver(version: PackedStringArray) -> bool:
	if version.size() != 3:
		return false
	for i in version:
		var v: String = i
		if not v.is_valid_int():
			return false
	return true

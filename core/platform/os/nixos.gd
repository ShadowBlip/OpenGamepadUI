extends OSPlatform
class_name PlatformNixOS


func _init() -> void:
	logger.set_name("PlatformNixOS")
	logger.set_level(Log.LEVEL.INFO)
	logger.info("Detected NixOS platform")


## NixOS typically cannot execute regular binaries, so downloaded binaries will
## be run with 'steam-run'. 
func get_binary_compatibility_cmd(cmd: String, args: PackedStringArray) -> Array[String]:
	# Hack for steam plugin running steamcmd on NixOS
	var command: Array[String] = []
	if not cmd.ends_with("steamcmd.sh"):
		return command

	command.push_back("steam-run")
	command.push_back(cmd)
	command.append_array(args)

	return command

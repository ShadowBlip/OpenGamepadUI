extends Resource
class_name APUDatabase

@export var apu_list: Array[APUEntry]
@export var database_name: String
var apu_map: Dictionary
var loaded := false

var logger := Log.get_logger(database_name + "APUDatabase", Log.LEVEL.INFO)


## Load entries that are set in the APUDatabase resource file into a map.
## NOTE: This needs to be called after _init() in order for the exported
## apu_list to be populated.
func load_db()-> void:
	logger.debug("Setting up APU database map.")
	for apu in apu_list:
		apu_map[apu.model_name] = apu
	loaded = true


## Returns an [APUEntry] of the given APU
func get_apu(apu_name: String) -> APUEntry:
	if not loaded:
		load_db()
	if not apu_name in apu_map:
		logger.info("APU " + apu_name + " not in APU Database")
		return null
	return apu_map[apu_name]

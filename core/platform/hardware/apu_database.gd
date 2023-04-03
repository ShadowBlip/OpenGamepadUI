extends Resource

class_name APUDatabase

const APUEntry := preload("res://core/platform/hardware/apu_entry.gd")

@export var apu_list: Array[APUEntry]
@export var database_name: String
var apu_map: Dictionary

var logger := Log.get_logger(database_name+"APUDatabase", Log.LEVEL.INFO)


func init()-> void:
	logger.debug("Setting up APU database map.")
	for apu in apu_list:
		apu_map[apu.model_name] = apu


func get_apu(apu_name: String) -> APUEntry:
	if not apu_name in apu_map:
		logger.info("APU " + apu_name + " not in APU Database")
		return null
	return apu_map[apu_name]	

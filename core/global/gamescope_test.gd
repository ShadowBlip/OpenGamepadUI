extends Node

func _ready() -> void:
	var gamescope := Gamescope.new()
	var to_int := gamescope._float_to_long(1.3)
	print(to_int)
	assert(to_int == 1067869798)
	
	var to_float := gamescope._long_to_float(to_int)
	print(to_float)
	assert(to_float > 1.2 and to_float <= 1.3)

extends Test


func _ready() -> void:
	var ryzenadj := RyzenAdj.new()
	var info := await ryzenadj.get_info()
	print(info.stapm_limit)
	
	ryzenadj.set_stapm_limit(44.60000 * 1000)

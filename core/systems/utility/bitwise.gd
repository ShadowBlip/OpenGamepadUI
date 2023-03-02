extends Object
class_name Bitwise


static func flags(flags: Array[int]) -> int:
	var result: int = 0
	for flag in flags:
		result = set_flag(result, flag)
	return result


static func has_flag(value: int, flag: int) -> bool:
	return value & flag


static func set_flag(value: int, flag: int) -> int:
	return value | flag


static func clear_flag(value: int, flag: int) -> int:
	return value & ~flag


static func toggle_flag(value: int, flag: int) -> int:
	return value ^ flag

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


static func set_flag_to(value: int, flag: int, enabled: bool) -> int:
	if enabled:
		return set_flag(value, flag)
	return clear_flag(value, flag)


static func clear_flag(value: int, flag: int) -> int:
	return value & ~flag


static func toggle_flag(value: int, flag: int) -> int:
	return value ^ flag

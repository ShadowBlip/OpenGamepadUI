extends DRMCardInfo
class_name DRMCardInfoIntel


## Reads the following sysfs paths and returns the current and mix/max gpu frequencies.
func get_clock_limits() -> Vector2:
	var limits := Vector2.ZERO
	var freq_min := _get_property("gt_RPn_freq_mhz")
	var freq_max := _get_property("gt_RP0_freq_mhz")
	
	if freq_min.is_valid_float():
		limits.x = freq_min.to_float()
	if freq_max.is_valid_float():
		limits.y = freq_max.to_float()
	
	return limits


## Returns a vector of the current min/max clock values
func get_clock_values() -> Vector2:
	var clock := Vector2.ZERO
	var min_str := _get_property("gt_min_freq_mhz")
	if min_str.is_valid_float():
		clock.x = min_str.to_float()
	var max_str := _get_property("gt_max_freq_mhz")
	if max_str.is_valid_float():
		clock.y = max_str.to_float()
	
	return clock

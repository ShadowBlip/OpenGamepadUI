extends DRMCardInfo
class_name DRMCardInfoAMD


## Reads the pp_od_clk_voltage from sysfs and returns the OD_RANGE values. This file will 
## be empty if not in "manual" for pp_od_performance_level.
func get_clock_limits() -> Vector2:
	var limits := Vector2.ZERO
	var result := _get_property("device/pp_od_clk_voltage").split("\n")
	for param in result:
		var parts := param.split("\n")
		for part in parts:
			var fixed_part := part.strip_edges().split(" ", false)
			if fixed_part.is_empty() or fixed_part in ["0:", "1:"]:
				continue
			if fixed_part[0] == "SCLK:":
				limits.x = int(fixed_part[1].rstrip("Mhz"))
				limits.y = int(fixed_part[2].rstrip("Mhz"))

	return limits


## Reads the pp_od_clk_voltage from sysfs and returns the OD_SCLK values. This file will 
## be empty if not in "manual" for pp_od_performance_level.
func get_clock_values() -> Vector2:
	var clock := Vector2.ZERO
	var data := _get_property("device/pp_od_clk_voltage")
	var result := data.split("\n")

	for param in result:
		var parts := param.split("\n")
		for part in parts:
			var fixed_part := part.strip_edges().split(" ", false)
			if fixed_part.is_empty() or fixed_part[0] == "SCLK:" :
				continue
			if fixed_part[0] == "0:":
				clock.x =  float(fixed_part[1].rstrip("Mhz"))
			elif fixed_part[0] == "1:":
				clock.y =  float(fixed_part[1].rstrip("Mhz"))

	return clock

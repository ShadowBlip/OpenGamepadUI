extends RefCounted
class_name RyzenAdj

## Ryzen Power Management adjust tool
##
## Adjust and query power management settings for Ryzen Mobile Processors

const POWERTOOLS_PATH := "/usr/share/opengamepadui/scripts/powertools"
const RYZENADJ_BIN := "ryzenadj"

## Corresponds to the '--max-performance' and '--power-saving' arguments.
enum POWER_PROFILE {
	POWER_SAVINGS,
	MAX_PERFORMANCE,
}

var thread := load("res://core/systems/threading/utility_thread.tres") as SharedThread
var logger := Log.get_logger("RyzenAdj")


## Set hidden option to improve performance/efficiency
func set_power_profile(profile: POWER_PROFILE) -> int:
	var arg := "--power-saving"
	if profile == POWER_PROFILE.MAX_PERFORMANCE:
		arg = "--max-performance"
	var cmd := await exec([arg])
	if cmd.code != OK:
		logger.error("Failed to set power profile for: " + arg.replace("--", ""))
	
	return cmd.code


## Sets the sustained power limit (STAPM LIMIT) to the given value
func set_stapm_limit(value: float) -> int:
	var cmd := await exec(["-a", str(round(value))])
	if cmd.code != OK:
		logger.error("Failed to set stapm limit to: " + str(value))
	
	return cmd.code


## Sets the actual power limit (PPT LIMIT FAST (mW)) to the given value
func set_fast_limit(value: float) -> int:
	var cmd := await exec(["-b", str(round(value))])
	if cmd.code != OK:
		logger.error("Failed to set fast limit to: " + str(value))
	
	return cmd.code


## Sets the average power limit (PPT LIMIT SLOW (mW)) to the given value
func set_slow_limit(value: float) -> int:
	var cmd := await exec(["-c", str(round(value))])
	if cmd.code != OK:
		logger.error("Failed to set slow limit to: " + str(value))
	
	return cmd.code


## Sets the tctl temperature limit (degree C) to the given value
func set_tctl_temp(value: float) -> int:
	var cmd := await exec(["-f", str(round(value))])
	if cmd.code != OK:
		logger.error("Failed to set tctl temperature to: " + str(value))
	
	return cmd.code


## Execute the ryzenadj command with the given arguments.
func exec(args: PackedStringArray) -> Command:
	var cmd := Command.new(POWERTOOLS_PATH, PackedStringArray([RYZENADJ_BIN]) + args, thread)
	var err := await cmd.execute() as int
	if err != OK:
		logger.error("Failed to execute command: " + str(cmd))
	
	return cmd


## Returns current power metrics. If ryzenadj fails to read a particular value,
## it will be set to -1.
func get_info() -> Info:
	# Execute 'ryzenadj -i'
	var cmd := await exec(["-i"])
	if cmd.code != OK:
		logger.error("Failed to execute ryzenadj info command")
		return null
	
	# Create a structure to store the info
	var info := Info.new()
	
	# Parse the ryzenadj output
	var lines := cmd.stdout.split("\n")
	for line in lines:
		var parts := line.split("|")
		for index in parts.size():
			parts[index] = parts[index].strip_edges()
		if len(parts) < 3:
			continue
		var key := parts[1] as String
		var value_str := parts[2] as String
		
		if not value_str.is_valid_float():
			logger.debug("Unable to parse value for " + key)
			continue
		var value := value_str.to_float()
		
		match key:
			"STAPM LIMIT":
				info.stapm_limit = value
			"STAPM VALUE":
				info.stapm_value = value
			"PPT LIMIT FAST":
				info.ppt_limit_fast = value
			"PPT VALUE FAST":
				info.ppt_value_fast = value
			"PPT LIMIT SLOW":
				info.ppt_limit_slow = value
			"PPT VALUE SLOW":
				info.ppt_value_slow = value
			"StapmTimeConst":
				info.stapm_time_const = value
			"SlowPPTTimeConst":
				info.slow_pptt_time_const = value
			"PPT LIMIT APU":
				info.ppt_limit_apu = value
			"PPT VALUE APU":
				info.ppt_value_apu = value
			"TDC LIMIT VDD":
				info.tdc_limit_vdd = value
			"TDC VALUE VDD":
				info.tdc_value_vdd = value
			"TDC LIMIT SOC":
				info.tdc_limit_soc = value
			"TDC VALUE SOC":
				info.tdc_value_soc = value
			"EDC LIMIT VDD":
				info.edc_limit_vdd = value
			"EDC VALUE VDD":
				info.edc_value_vdd = value
			"EDC LIMIT SOC":
				info.edc_limit_soc = value
			"EDC VALUE SOC":
				info.edc_value_soc = value
			"THM LIMIT CORE":
				info.thm_limit_core = value
			"THM VALUE CORE":
				info.thm_value_core = value
			"STT LIMIT APU":
				info.stt_limit_apu = value
			"STT VALUE APU":
				info.stt_value_apu = value
			"STT LIMIT dGPU":
				info.stt_limit_dgpu = value
			"STT VALUE dGPU":
				info.stt_value_dgpu = value
			"CCLK Boost SETPOINT":
				info.cclk_boost_setpoint = value
			"CCLK BUSY VALUE":
				info.cclk_busy_value = value
	
	return info


## Container for holding power metrics from RyzenAdj
class Info:
	var stapm_limit := -1.0
	var stapm_value := -1.0
	var ppt_limit_fast := -1.0
	var ppt_value_fast := -1.0
	var ppt_limit_slow := -1.0
	var ppt_value_slow := -1.0
	var stapm_time_const := -1.0
	var slow_pptt_time_const := -1.0
	var ppt_limit_apu := -1.0
	var ppt_value_apu := -1.0
	var tdc_limit_vdd := -1.0
	var tdc_value_vdd := -1.0
	var tdc_limit_soc := -1.0
	var tdc_value_soc := -1.0
	var edc_limit_vdd := -1.0
	var edc_value_vdd := -1.0
	var edc_limit_soc := -1.0
	var edc_value_soc := -1.0
	var thm_limit_core := -1.0
	var thm_value_core := -1.0
	var stt_limit_apu := -1.0
	var stt_value_apu := -1.0
	var stt_limit_dgpu := -1.0
	var stt_value_dgpu := -1.0
	var cclk_boost_setpoint := -1.0
	var cclk_busy_value := -1.0

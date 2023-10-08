extends PerformanceGPU
class_name PerformanceIntelGPU

var hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager
var logger := Log.get_logger("PerformanceIntelGPU")


## Retrieves the current TDP from sysfs for Intel iGPU's.
func get_tdp() -> Info:
	var tdp_info := Info.new()
	var long_tdp := float(_read_sys("/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw"))
	if not long_tdp:
		logger.warn("Unable to determine long TDP.")
		return null

	tdp_info.tdp_current = long_tdp / 1000000
	var peak_tdp := float(_read_sys("/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_2_power_limit_uw"))
	if not peak_tdp:
		logger.warn("Unable to determine long TDP.")
		return null
	tdp_info.tdp_boost_current = peak_tdp / 1000000 - tdp_info.tdp_current
	
	return tdp_info


## Called to set the maximum gpu clock
func set_gpu_freq_max(value: float) -> void:
	if value == 0:
		logger.warn("Cowardly refusing to set maximum clock rate to 0")
		return

	# Get the active GPU
	var card := hardware_manager.get_active_gpu_card()
	if not card:
		logger.warn("Unable to detect active GPU card to set frequency")
		return
	
	# Get the current minimum clock rate
	var values := card.get_clock_values()
	if values == Vector2.ZERO:
		logger.warn("Unable to read clock values to set frequency")
		return
	
	if await set_gpu_freq(values.x, value) != OK:
		logger.warn("Error setting GPU max frequency")


## Called to set the minimum gpu clock
func set_gpu_freq_min(value: float) -> void:
	if value == 0:
		logger.warn("Cowardly refusing to set minimum clock rate to 0")
		return

	# Get the active GPU
	var card := hardware_manager.get_active_gpu_card()
	if not card:
		logger.warn("Unable to detect active GPU card to set frequency")
		return
	
	# Get the current maximum clock rate
	var values := card.get_clock_values()
	if values == Vector2.ZERO:
		logger.warn("Unable to read clock values to set frequency")
		return
	
	if await set_gpu_freq(value, values.y) != OK:
		logger.warn("Error setting GPU min frequency")


# Sets the GPU frequency range to the given values
## Sets the GPU frequency range to the given values
func set_gpu_freq(freq_min: int, freq_max: int) -> int:
	# Get the active GPU
	var card := hardware_manager.get_active_gpu_card()
	if not card:
		logger.warn("Unable to detect active GPU card to set frequency")
		return -1

	var args := ["intelGpuClock", str(freq_min), str(freq_max), card.name]
	var cmd := Command.new(POWERTOOLS_PATH, args)
	return await cmd.execute()


func set_tdp_boost_value(value: float) -> void:
	logger.debug("Setting TDP boost value to: " + str(value))
	var tdp_info := get_tdp()
	if not tdp_info:
		logger.warn("Unable to get current TDP to set boost value")
		return
	
	var shortTDP: float = (floor(tdp_info.tdp_boost_current/2) + tdp_info.tdp_current) * 1000000
	var peakTDP: float = (tdp_info.tdp_boost_current + tdp_info.tdp_current) * 1000000
	
	var cmd1 := Command.new(POWERTOOLS_PATH, ["setRapl", "constraint_1_power_limit_uw", str(shortTDP)])
	if await cmd1.execute() != OK:
		logger.warn("Unable to set constraint 1 power limit: " + cmd1.stdout)
		return

	var cmd2 := Command.new(POWERTOOLS_PATH, ["setRapl", "constraint_2_power_limit_uw", str(peakTDP)])
	if await cmd2.execute() != OK:
		logger.warn("Unable to set constraint 2 power limit: " + cmd2.stdout)
		return


func set_tdp_value(value: float) -> void:
	logger.debug("Setting TDP value to: " + str(value))
	var tdp_info := get_tdp()
	if not tdp_info:
		logger.warn("Unable to get current TDP to set value")
		return

	var cmd := Command.new(POWERTOOLS_PATH, ["setRapl", "constraint_0_power_limit_uw", str(tdp_info.tdp_current * 1000000)])
	if await cmd.execute() != OK:
		logger.warn("Error setting TDP value: " + cmd.stdout)

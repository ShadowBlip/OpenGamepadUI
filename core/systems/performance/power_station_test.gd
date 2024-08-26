extends GutTest


func test_cpu() -> void:
	var powerstation := PowerStation.new()
	powerstation.instance = load("res://core/systems/performance/power_station.tres") as PowerStationInstance
	add_child_autoqfree(powerstation)

	if not powerstation.instance.is_running():
		pass_test("PowerStation is not running, skipping")
		return
	var cpu := powerstation.instance.get_cpu()
	assert_not_null(cpu, "should return CPU instance")

	# Test getting total number of cpu cores
	var num_cores := cpu.cores_count
	gut.p("Total CPU cores: " + str(num_cores))
	assert_ne(num_cores, -1, "should have returned total core count")

	# Test getting features
	var features := cpu.features
	gut.p("Found CPU features: " + str(features))
	assert_gt(features.size(), 1, "should return CPU features")
	if features.size() > 1:
		var feature := features[0] as String
		assert_true(cpu.has_feature(feature), "should have CPU feature")
		assert_false(cpu.has_feature("IdontXsist!"), "should not have CPU feature")

	# Test that CPU cores get set
	gut.p("Disabling one CPU core")
	cpu.cores_enabled = num_cores - 1
	gut.p("Cores enabled: " + str(cpu.cores_enabled))
	assert_eq(cpu.cores_enabled, num_cores - 1, "should have disabled cores")

	# Set the cores back
	gut.p("Re-enabling CPU core")
	cpu.cores_enabled = num_cores
	gut.p("Cores enabled: " + str(cpu.cores_enabled))
	assert_eq(cpu.cores_enabled, num_cores, "should have re-enabled all cores")

	# Test setting SMT
	cpu.smt_enabled = false
	assert_false(cpu.smt_enabled, "should have disabled SMT")
	await wait_frames(1, "wait for change")
	cpu.smt_enabled = true
	assert_true(cpu.smt_enabled, "should have enabled SMT")
	await wait_frames(1, "wait for change")

	# Test setting boost
	cpu.boost_enabled = false
	#assert_false(cpu.boost_enabled, "should have disabled boost")
	await wait_frames(1, "wait for change")
	cpu.boost_enabled = true
	#assert_true(cpu.boost_enabled, "should have enabled boost")
	await wait_frames(1, "wait for change")

	# Test enumerating cores
	var cores := cpu.get_cores()
	assert_gt(cores.size(), 0, "should return at least 1 cpu core")
	for core in cores:
		gut.p("CPU Core: " + str(core.number))
		gut.p("  ID: " + str(core.core_id))
		gut.p("  Online: " + str(core.online))


func test_gpu() -> void:
	var powerstation := PowerStation.new()
	powerstation.instance = load("res://core/systems/performance/power_station.tres") as PowerStationInstance
	add_child_autoqfree(powerstation)

	if not powerstation.instance.is_running():
		pass_test("PowerStation is not running, skipping")
		return
	var gpu := powerstation.instance.get_gpu()
	assert_not_null(gpu, "should return GPU instance")

	# Test all GPU card methods
	var cards := gpu.get_cards()
	for card in cards:
		gut.p("Got card: " + card.device)
		if not card.supports_tdp():
			continue
		gut.p("Card supports TDP control: " + card.device)
		
		# TDP Control
		var tdp := card.tdp
		card.tdp = 10.0
		assert_eq(card.tdp, 10.0, "TDP value should have changed")
		card.tdp = tdp
		
		# TDP Boost
		var boost := card.boost
		card.boost = 2.0
		assert_eq(card.boost, 2.0, "Boost should have changed")
		card.boost = boost
		
		# Power profile
		var profile := card.power_profile
		card.power_profile = "max-performance"
		assert_eq(card.power_profile, "max-performance")
		card.power_profile = profile

		# GPU temperature control
		var temp := card.thermal_throttle_limit_c
		card.thermal_throttle_limit_c = 97.0
		assert_eq(card.thermal_throttle_limit_c, 97.0)
		card.thermal_throttle_limit_c = temp

extends GutTest

var power_station := load("res://core/systems/performance/power_station.tres") as PowerStation


func test_cpu() -> void:
	if not power_station.supports_power_station():
		pass_test("PowerStation is not running, skipping")
		return
	var cpu := power_station.cpu
	assert_not_null(cpu, "should return CPU instance")

	# Test getting total number of cpu cores
	var num_cores = cpu.cores_count
	assert_ne(num_cores, -1, "should have returned total core count")

	# Test that CPU cores get set
	cpu.cores_enabled = num_cores - 1
	assert_eq(cpu.cores_enabled, num_cores - 1, "should have disabled cores")
	
	# Set the cores back
	cpu.cores_enabled = num_cores
	assert_eq(cpu.cores_enabled, num_cores, "should have re-enabled all cores")

	# Test enumerating cores
	var enumerated := cpu.enumerate_cores()
	assert_gt(enumerated.size(), 0, "should return at least 1 cpu core path")

	# Test getting features
	var features = cpu.features
	assert_gt(features.size(), 1, "should return CPU features")
	if features.size() > 1:
		var feature := features[0] as String
		assert_true(cpu.has_feature(feature), "should have CPU feature")
		assert_false(cpu.has_feature("IdontXsist!"), "should not have CPU feature")

	# Test setting SMT
	cpu.smt_enabled = false
	assert_false(cpu.smt_enabled, "should have disabled SMT")
	await wait_frames(1, "wait for change")
	cpu.smt_enabled = true
	assert_true(cpu.smt_enabled, "should have enabled SMT")
	await wait_frames(1, "wait for change")

	# Test setting boost
	cpu.boost_enabled = false
	assert_false(cpu.boost_enabled, "should have disabled boost")
	await wait_frames(1, "wait for change")
	cpu.boost_enabled = true
	assert_true(cpu.boost_enabled, "should have enabled boost")
	await wait_frames(1, "wait for change")


func test_gpu() -> void:
	if not power_station.supports_power_station():
		pass_test("PowerStation is not running, skipping")
		return
	var gpu := power_station.gpu
	assert_not_null(gpu, "should return GPU instance")

	# Test enumerating cards
	var card_paths := gpu.enumerate_cards()
	#assert_gt(cards.size(), 0, "should return at least 1 gpu")

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

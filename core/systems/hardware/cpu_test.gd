extends GutTest

var hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager
var cpu := hardware_manager.get_cpu()

func before_all() -> void:
	gut.p(cpu)


func test_get_cpu_cores() -> void:
	for core in cpu.get_cores():
		gut.p(core)

	pass_test("Skipping")


func test_cpu_boost() -> void:
	cpu.set_boost_enabled(false)
	gut.p("Boost: " + str(cpu.get_boost_enabled()))
	cpu.set_boost_enabled(true)
	gut.p("Boost: " + str(cpu.get_boost_enabled()))

	pass_test("Skipping")


func test_cpu_core_enable() -> void:
	var core := cpu.get_core(10)
	core.changed.connect(_on_core_changed)
	if core.set_online(false) != OK:
		gut.p("Failed to turn off core")
	if core.set_online(true) != OK:
		gut.p("Failed to turn on core")

	pass_test("Skipping")


func test_set_cpu_core_count() -> void:
	cpu.set_cpu_core_count(2)
	cpu.set_cpu_core_count(cpu.get_total_core_count())

	pass_test("Skipping")


func _on_core_changed() -> void:
	gut.p("Core state changed!")

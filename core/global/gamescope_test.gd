extends GutTest

var gamescope := Gamescope.new()


func test_float_to_long() -> void:
	var to_int := gamescope._float_to_long(1.3)
	gut.p(to_int)
	assert_eq(to_int, 1067869798, "should be converted to a long")


func test_long_to_float() -> void:
	var to_float := gamescope._long_to_float(1067869798)
	gut.p(to_float)
	assert_almost_eq(to_float, 1.3, 0.01, "should be approximately 1.3")

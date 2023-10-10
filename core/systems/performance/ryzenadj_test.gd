extends GutTest

var ryzenadj := RyzenAdj.new()
var supports_ryzenadj := has_ryzenadj()


func has_ryzenadj() -> bool:
	return OS.execute("which", ["ryzenadj"]) == OK


func test_get_info() -> void:
	if not supports_ryzenadj:
		pass_test("ryzenadj not installed, skipping")
		return
	var info := await ryzenadj.get_info()
	assert_not_null(info, "should return ryzenadj info")

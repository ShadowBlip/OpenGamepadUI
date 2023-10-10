extends GutTest

var version := "1.3.24"


func test_semver_validation() -> void:
	assert_true(SemanticVersion.is_valid(version), "should be a valid semver")
	assert_false(SemanticVersion.is_valid("v1.0.0"), "should be invalid")
	assert_false(SemanticVersion.is_valid("1.0.invalid"), "should be invalid")


func test_version_comparisons() -> void:
	assert_true(SemanticVersion.is_greater(version, "2.0.0"), "should be greater")
	assert_true(SemanticVersion.is_greater(version, "1.4.0"), "should be greater")
	assert_true(SemanticVersion.is_greater(version, "1.3.25"), "should be greater")
	assert_false(SemanticVersion.is_greater(version, "1.3.24"), "should be equal")
	assert_false(SemanticVersion.is_greater(version, "1.2.28"), "should be less")
	assert_false(SemanticVersion.is_greater(version, "0.2.28"), "should be less")
	assert_true(SemanticVersion.is_greater_or_equal(version, "1.3.24"), "should be equal")
	assert_false(SemanticVersion.is_greater_or_equal(version, "1.3.23"), "should be less")


func test_feature_compatibility() -> void:
	# E.g. v1.3.24 is feature compatible with v1.4.0, but not v1.2.0
	assert_true(SemanticVersion.is_feature_compatible(version, "1.3.0"), "should be compatible")
	assert_true(SemanticVersion.is_feature_compatible(version, "1.4.0"), "should be compatible")
	assert_false(SemanticVersion.is_feature_compatible(version, "1.2.0"), "should not be compatible")
	assert_false(SemanticVersion.is_feature_compatible(version, "4.3.0"), "should not be compatible")

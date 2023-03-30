extends Test


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var version := "1.3.24"
	
	# Test semver validation
	assert_true(SemanticVersion.is_valid(version))
	assert_true(not SemanticVersion.is_valid("v1.0.0"))
	assert_true(not SemanticVersion.is_valid("1.0.invalid"))

	# Test version comparisons
	assert_true(SemanticVersion.is_greater(version, "2.0.0"))
	assert_true(SemanticVersion.is_greater(version, "1.4.0"))
	assert_true(SemanticVersion.is_greater(version, "1.3.25"))
	assert_true(not SemanticVersion.is_greater(version, "1.3.24"))
	assert_true(not SemanticVersion.is_greater(version, "1.2.28"))
	assert_true(not SemanticVersion.is_greater(version, "0.2.28"))
	assert_true(SemanticVersion.is_greater_or_equal(version, "1.3.24"))
	assert_true(not SemanticVersion.is_greater_or_equal(version, "1.3.23"))
	
	# Test feature compatibility
	# E.g. v1.3.24 is feature compatible with v1.4.0, but not v1.2.0
	assert_true(SemanticVersion.is_feature_compatible(version, "1.3.0"))
	assert_true(SemanticVersion.is_feature_compatible(version, "1.4.0"))
	assert_true(not SemanticVersion.is_feature_compatible(version, "1.2.0"))
	assert_true(not SemanticVersion.is_feature_compatible(version, "4.3.0"))

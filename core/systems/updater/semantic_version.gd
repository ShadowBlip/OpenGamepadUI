extends RefCounted
class_name SemanticVersion

## Static methods for semantic versioning
##
## Provides static methods for working with semantic version numbers. Semantic
## version numbers are in the form of Y.X.Z, where Y is the major version,
## X is the minor version, and Z is the patch version. Changes to the major
## version indicate a backwards compatible breaking change. Changes to the minor
## version indicate new features. Changes to the patch version indicate bug
## fixes.


## Returns whether or not the given version is feature compatible with
## the target version.
## E.g. v1.4.3 is feature compatible with v1.4.0, but not v1.3.0
static func is_feature_compatible(version: String, target: String) -> bool:
	# Ensure the given versions are valid semver
	if not is_valid(version) or not is_valid(target):
		return false
		
	var version_list := version.split(".")
	var target_list := target.split(".")
	
	# Compare major versions: X.x.x
	# Major version must match exactly
	if version_list[0] != target_list[0]:
		return false
	
	# Compare minor versions: x.X.x
	# Minor version must be less than or equal to the target version
	if version_list[1] <= target_list[1]:
		return true
	
	return false


## Returns whether or not the given semantic version string is greater or equal
## to the target semantic version string.
static func is_greater_or_equal(version: String, target: String) -> bool:
	# Ensure the given versions are valid semver
	if not is_valid(version) or not is_valid(target):
		return false
	
	# Return true if the versions exactly match
	if version == target:
		return true
		
	return is_greater(version, target)


## Returns whether or not the given semantic version string is greater than 
## the target semantic version string.  
static func is_greater(version: String, target: String) -> bool:
	# Ensure the given versions are valid semver
	if not is_valid(version) or not is_valid(target):
		return false
		
	var version_list := version.split(".")
	var target_list := target.split(".")
	
	# Compare major versions: X.x.x
	if target_list[0] > version_list[0]:
		return true
	var matches_major := false
	if target_list[0] == version_list[0]:
		matches_major = true
	
	# Compare minor versions: x.X.x
	if matches_major and target_list[1] > version_list[1]:
		return true
	var matches_minor := false
	if target_list[1] == version_list[1]:
		matches_minor = true
	
	# Compare patch versions: x.x.X
	if matches_minor and target_list[2] > version_list[2]:
		return true
		
	return false


## Returns whether or not the given version string is a valid semantic version
## string. Semantic version strings are in the form of X.Y.Z (e.g. 1.3.24)
static func is_valid(version: String) -> bool:
	var version_list := version.split(".")
	if version_list.size() != 3:
		return false
	for i in version_list:
		var v: String = i
		if not v.is_valid_int():
			return false
	return true

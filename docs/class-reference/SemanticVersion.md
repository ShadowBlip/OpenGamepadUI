# SemanticVersion

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Static methods for semantic versioning
## Description

Provides static methods for working with semantic version numbers. Semantic version numbers are in the form of Y.X.Z, where Y is the major version, X is the minor version, and Z is the patch version. Changes to the major version indicate a backwards compatible breaking change. Changes to the minor version indicate new features. Changes to the patch version indicate bug fixes.
## Methods

| Returns | Signature |
| ------- | --------- |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_feature_compatible](./#is_feature_compatible)(version: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), target: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_greater_or_equal](./#is_greater_or_equal)(version: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), target: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_greater](./#is_greater)(version: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), target: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_valid](./#is_valid)(version: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |


------------------

## Method Descriptions

### `is_feature_compatible()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_feature_compatible**(version: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), target: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns whether or not the given version is feature compatible with the target version. E.g. v1.4.3 is feature compatible with v1.4.0, but not v1.3.0
### `is_greater_or_equal()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_greater_or_equal**(version: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), target: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns whether or not the given semantic version string is greater or equal to the target semantic version string.
### `is_greater()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_greater**(version: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), target: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns whether or not the given semantic version string is greater than the target semantic version string.
### `is_valid()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_valid**(version: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns whether or not the given version string is a valid semantic version string. Semantic version strings are in the form of X.Y.Z (e.g. 1.3.24)

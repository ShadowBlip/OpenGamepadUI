# Feature

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Definition of a single feature flag
## Description

A Feature describes one toggleable behavior: its id, description, and default state. Feature objects hold no logic and are registered with [FeatureFlags](../FeatureFlags).
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [id](./#id) | "" |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [description](./#description) | "" |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [default](./#default) | false |

## Methods

| Returns | Signature |
| ------- | --------- |
| [Feature](../Feature) | [create](./#create)(feature_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), feature_default: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = false, feature_description: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [normalize](./#normalize)(feature_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |


------------------

## Property Descriptions

### `id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) id = <span style="color: red;">""</span>


The normalized identifier of this feature (lowercase, hyphen-separated).
### `description`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) description = <span style="color: red;">""</span>


Human-readable description, used by help output and settings UI.
### `default`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) default = <span style="color: red;">false</span>


The state this feature has when no source overrides it.



------------------

## Method Descriptions

### `create()`


[Feature](../Feature) **create**(feature_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), feature_default: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = false, feature_description: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Creates a new feature with a normalized id.
### `normalize()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **normalize**(feature_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Normalizes a feature id: lowercase, with underscores and spaces replaced by hyphens.

extends Resource
class_name Feature

## Definition of a single feature flag
##
## A Feature describes one toggleable behavior: its id, description, and default
## state. Feature objects hold no logic and are registered with [FeatureFlags].

## The normalized identifier of this feature (lowercase, hyphen-separated).
@export var id: String = ""

## Human-readable description, used by help output and settings UI.
@export var description: String = ""

## The state this feature has when no source overrides it.
@export var default: bool = false


## Creates a new feature with a normalized id.
static func create(feature_id: String, feature_default: bool = false, feature_description: String = "") -> Feature:
	var feature := Feature.new()
	feature.id = normalize(feature_id)
	feature.description = feature_description
	feature.default = feature_default
	return feature


## Normalizes a feature id: lowercase, with underscores and spaces replaced by hyphens.
static func normalize(feature_id: String) -> String:
	return feature_id.to_lower().replace("_", "-").replace(" ", "-")

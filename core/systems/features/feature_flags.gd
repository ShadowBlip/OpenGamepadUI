extends Resource
class_name FeatureFlags

## Registry of feature flags
##
## FeatureFlags parses command-line arguments and environment variables to turn
## features on or off, and allows features to be toggled at runtime by plugins and
## platform classes. Signals are emitted when a feature changes so the UI can react.

signal feature_registered(feature: Feature)
signal feature_changed(feature: Feature, enabled: bool)
signal feature_enabled(feature: Feature)
signal feature_disabled(feature: Feature)

## Where the current value of a feature came from.
enum Source { DEFAULT, ENV, ARG, RUNTIME }

## Environment variable prefix for a single feature, e.g. OGUI_FEATURE_UPDATER=0.
const ENV_PREFIX := "OGUI_FEATURE_"

## Environment variable containing a list of features to enable.
const ENV_LIST := "OGUI_FEATURES"

## Environment variable containing a list of features to disable.
const ENV_DISABLED_LIST := "OGUI_DISABLED_FEATURES"

## Command-line argument prefix for a single feature, e.g. --feature-no-updater.
const ARG_PREFIX := "--feature-"

const TRUTHY := ["1", "true", "yes", "on"]
const FALSY := ["0", "false", "no", "off"]

## The registered features.
@export var features: Array[Feature] = []

var _env: Dictionary = {}
var _env_overrides: Dictionary[String, bool] = {}
var _arg_overrides: Dictionary[String, bool] = {}
var _runtime_overrides: Dictionary[String, bool] = {}
var logger: CustomLogger = Log.get_logger("FeatureFlags")


func _init() -> void:
	load_from_os()


## Registers a feature. Returns OK if the feature was newly registered.
func register_feature(feature: Feature) -> Error:
	if not feature or feature.id == "":
		logger.warn("Cannot register a feature without an id")
		return Error.ERR_INVALID_PARAMETER
	feature.id = Feature.normalize(feature.id)
	if get_feature(feature.id):
		return Error.ERR_ALREADY_EXISTS
	features.append(feature)
	feature_registered.emit(feature)
	var value := _resolve(feature.id)
	if value != feature.default:
		_emit_change(feature, value)
	return Error.OK


## Returns the registered feature with the given id, or null if it is not registered.
func get_feature(id: String) -> Feature:
	var normalized := Feature.normalize(id)
	for feature in features:
		if feature and Feature.normalize(feature.id) == normalized:
			return feature
	return null


## Returns all registered features.
func get_features() -> Array[Feature]:
	return features


## Returns whether the given feature is enabled. Unknown features return false.
func is_enabled(id: String) -> bool:
	var normalized := Feature.normalize(id)
	var feature := get_feature(normalized)
	if not feature:
		logger.warn("Unknown feature: " + normalized)
		return false
	return _resolve(normalized)


## Sets a feature at runtime. The runtime value takes precedence over all sources.
func set_feature(id: String, enabled: bool) -> void:
	var normalized := Feature.normalize(id)
	if not get_feature(normalized):
		logger.warn("Cannot set unknown feature: " + normalized)
		return
	_apply(normalized, enabled, Source.RUNTIME)


func enable(id: String) -> void:
	set_feature(id, true)


func disable(id: String) -> void:
	set_feature(id, false)


func toggle(id: String) -> void:
	set_feature(id, not is_enabled(id))


## Clears the runtime override so the feature resolves from its sources again.
func reset(id: String) -> void:
	var normalized := Feature.normalize(id)
	if not _runtime_overrides.has(normalized):
		return
	var before := _resolve(normalized)
	_runtime_overrides.erase(normalized)
	var feature := get_feature(normalized)
	if not feature or before == _resolve(normalized):
		return
	_emit_change(feature, _resolve(normalized))


## Returns which source produced the current value of the given feature.
func get_source(id: String) -> int:
	var normalized := Feature.normalize(id)
	if _runtime_overrides.has(normalized):
		return Source.RUNTIME
	if _arg_overrides.has(normalized):
		return Source.ARG
	if _has_env_value(normalized):
		return Source.ENV
	return Source.DEFAULT


## Clears all parsed values so the sources can be applied again.
func clear_sources() -> void:
	_env = {}
	_env_overrides.clear()
	_arg_overrides.clear()
	_runtime_overrides.clear()


## Applies the given command-line arguments. Testable entrypoint.
func parse_args(args: Array[String]) -> void:
	for arg in args:
		if not arg.begins_with(ARG_PREFIX):
			continue
		var id := arg.trim_prefix(ARG_PREFIX)
		var enabled := true
		if id.begins_with("no-"):
			enabled = false
			id = id.trim_prefix("no-")
		if id == "":
			continue
		_apply(Feature.normalize(id), enabled, Source.ARG)


## Applies the given environment variables. Testable entrypoint.
func parse_env(env: Dictionary) -> void:
	_env = env
	# Bulk lists are applied first so per-feature variables take precedence.
	for id in _parse_list(str(env.get(ENV_LIST, ""))):
		_apply(id, true, Source.ENV)
	for id in _parse_list(str(env.get(ENV_DISABLED_LIST, ""))):
		_apply(id, false, Source.ENV)
	for key in env:
		var name := str(key)
		if not name.begins_with(ENV_PREFIX):
			continue
		var raw := str(env[key])
		if not _is_bool_string(raw):
			logger.warn("Unable to parse value for " + name + ", using default")
			continue
		_apply(Feature.normalize(name.trim_prefix(ENV_PREFIX)), _to_bool(raw), Source.ENV)


## Parses the process command-line arguments and environment.
func load_from_os() -> void:
	parse_args(OS.get_cmdline_args())
	parse_env(_collect_env())


func _resolve(id: String) -> bool:
	if _runtime_overrides.has(id):
		return _runtime_overrides[id]
	if _arg_overrides.has(id):
		return _arg_overrides[id]
	if _has_env_value(id):
		return _env_value(id)
	var feature := get_feature(id)
	if not feature:
		return false
	return feature.default


func _has_env_value(id: String) -> bool:
	return _env_overrides.has(id) or _is_bool_string(_read_env(ENV_PREFIX + _env_key(id)))


func _env_value(id: String) -> bool:
	if _env_overrides.has(id):
		return _env_overrides[id]
	return _to_bool(_read_env(ENV_PREFIX + _env_key(id)))


func _apply(id: String, value: bool, source: int) -> void:
	var before := _resolve(id)
	if source == Source.RUNTIME:
		_runtime_overrides[id] = value
	elif source == Source.ARG:
		_arg_overrides[id] = value
	elif source == Source.ENV:
		_env_overrides[id] = value
	if before == value:
		return
	var feature := get_feature(id)
	if not feature:
		return
	_emit_change(feature, value)


func _emit_change(feature: Feature, value: bool) -> void:
	feature_changed.emit(feature, value)
	if value:
		feature_enabled.emit(feature)
	else:
		feature_disabled.emit(feature)


func _read_env(name: String) -> String:
	if _env.has(name):
		return str(_env[name])
	return OS.get_environment(name)


func _collect_env() -> Dictionary:
	var env := {}
	env[ENV_LIST] = OS.get_environment(ENV_LIST)
	env[ENV_DISABLED_LIST] = OS.get_environment(ENV_DISABLED_LIST)
	for feature in features:
		if not feature:
			continue
		var name := ENV_PREFIX + _env_key(feature.id)
		env[name] = OS.get_environment(name)
	return env


func _env_key(id: String) -> String:
	return id.replace("-", "_").to_upper()


func _is_bool_string(raw: String) -> bool:
	var value := raw.to_lower()
	return value in TRUTHY or value in FALSY


func _to_bool(raw: String) -> bool:
	return raw.to_lower() in TRUTHY


func _parse_list(raw: String) -> Array[String]:
	var ids: Array[String] = []
	for part in raw.replace(",", " ").split(" "):
		if part == "":
			continue
		ids.append(Feature.normalize(part))
	return ids

extends GutTest

var feature_flags: FeatureFlags
var updater: Feature


func before_each() -> void:
	feature_flags = FeatureFlags.new()
	feature_flags.clear_sources()
	updater = Feature.create("updater", true, "Allow checking for updates")
	feature_flags.register_feature(updater)
	watch_signals(feature_flags)


func test_default_value() -> void:
	assert_true(feature_flags.is_enabled("updater"))
	assert_eq(feature_flags.get_source("updater"), FeatureFlags.Source.DEFAULT)
	var offline := Feature.create("offline", false)
	feature_flags.register_feature(offline)
	assert_false(feature_flags.is_enabled("offline"))


func test_unknown_feature_returns_false() -> void:
	assert_false(feature_flags.is_enabled("nope"))
	assert_null(feature_flags.get_feature("nope"))


func test_duplicate_registration_returns_error() -> void:
	assert_eq(feature_flags.register_feature(Feature.create("updater")), Error.ERR_ALREADY_EXISTS)
	assert_eq(len(feature_flags.get_features()), 1)


func test_register_feature_emits_registered() -> void:
	var offline := Feature.create("offline")
	feature_flags.register_feature(offline)
	assert_signal_emitted_with_parameters(feature_flags, "feature_registered", [offline])


func test_normalizes_feature_ids() -> void:
	var feature := Feature.create("Steam_Deck Mode")
	assert_eq(feature.id, "steam-deck-mode")
	feature_flags.register_feature(feature)
	feature_flags.parse_args(["--feature-STEAM-DECK-MODE"])
	assert_true(feature_flags.is_enabled("Steam_Deck_Mode"))


func test_env_variable_sets_feature() -> void:
	feature_flags.parse_env({"OGUI_FEATURE_UPDATER": "0"})
	assert_false(feature_flags.is_enabled("updater"))
	assert_eq(feature_flags.get_source("updater"), FeatureFlags.Source.ENV)


func test_env_truthy_values() -> void:
	var values: Array[String] = ["1", "true", "yes", "on"]
	for value in values:
		feature_flags.clear_sources()
		feature_flags.parse_env({"OGUI_FEATURE_UPDATER": value})
		assert_true(feature_flags.is_enabled("updater"), "Expected true for value: " + value)


func test_env_unparseable_value_uses_default() -> void:
	feature_flags.parse_env({"OGUI_FEATURE_UPDATER": "maybe"})
	assert_true(feature_flags.is_enabled("updater"))
	assert_eq(feature_flags.get_source("updater"), FeatureFlags.Source.DEFAULT)


func test_env_feature_registered_after_parse_uses_env() -> void:
	feature_flags.parse_env({"OGUI_FEATURE_OFFLINE": "0"})
	var offline := Feature.create("offline", true)
	feature_flags.register_feature(offline)
	assert_false(feature_flags.is_enabled("offline"))


func test_env_bulk_lists() -> void:
	feature_flags.parse_env({"OGUI_FEATURES": "offline, steam-deck-mode"})
	feature_flags.register_feature(Feature.create("offline", false))
	feature_flags.register_feature(Feature.create("steam_deck_mode", false))
	assert_true(feature_flags.is_enabled("offline"))
	assert_true(feature_flags.is_enabled("steam-deck-mode"))
	assert_true(feature_flags.is_enabled("updater"))


func test_env_bulk_disable_list() -> void:
	feature_flags.parse_env({"OGUI_DISABLED_FEATURES": "updater"})
	assert_false(feature_flags.is_enabled("updater"))


func test_args_enable_and_disable() -> void:
	feature_flags.parse_args(["--feature-offline", "--feature-no-updater"])
	feature_flags.register_feature(Feature.create("offline", false))
	assert_true(feature_flags.is_enabled("offline"))
	assert_false(feature_flags.is_enabled("updater"))
	assert_eq(feature_flags.get_source("updater"), FeatureFlags.Source.ARG)


func test_precedence_runtime_over_arg_over_env_over_default() -> void:
	feature_flags.parse_env({"OGUI_FEATURE_UPDATER": "0"})
	assert_false(feature_flags.is_enabled("updater"))
	feature_flags.parse_args(["--feature-updater"])
	assert_true(feature_flags.is_enabled("updater"))
	feature_flags.set_feature("updater", false)
	assert_false(feature_flags.is_enabled("updater"))
	assert_eq(feature_flags.get_source("updater"), FeatureFlags.Source.RUNTIME)


func test_reset_clears_runtime_override() -> void:
	feature_flags.parse_env({"OGUI_FEATURE_UPDATER": "0"})
	feature_flags.set_feature("updater", true)
	assert_true(feature_flags.is_enabled("updater"))
	feature_flags.reset("updater")
	assert_false(feature_flags.is_enabled("updater"))
	assert_eq(feature_flags.get_source("updater"), FeatureFlags.Source.ENV)


func test_toggle() -> void:
	feature_flags.toggle("updater")
	assert_false(feature_flags.is_enabled("updater"))


func test_signals_on_change() -> void:
	feature_flags.disable("updater")
	assert_signal_emitted_with_parameters(feature_flags, "feature_changed", [updater, false])
	assert_signal_emitted(feature_flags, "feature_disabled")
	feature_flags.enable("updater")
	assert_signal_emitted_with_parameters(feature_flags, "feature_changed", [updater, true])
	assert_signal_emitted(feature_flags, "feature_enabled")


func test_no_signal_when_value_unchanged() -> void:
	feature_flags.enable("updater")
	assert_signal_not_emitted(feature_flags, "feature_changed")


func test_signal_on_registration_when_overridden() -> void:
	feature_flags.parse_env({"OGUI_FEATURE_OFFLINE": "1"})
	var offline := Feature.create("offline", false)
	feature_flags.register_feature(offline)
	assert_signal_emitted_with_parameters(feature_flags, "feature_changed", [offline, true])

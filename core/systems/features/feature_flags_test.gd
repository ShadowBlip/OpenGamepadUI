extends GutTest

var feature_flags: FeatureFlags


func before_each() -> void:
	feature_flags = FeatureFlags.new()
	feature_flags.clear_sources()
	feature_flags.register_feature(Feature.create("updater", true, "Allow checking for updates"))
	watch_signals(feature_flags)


func test_default_value_and_unknown_feature() -> void:
	assert_true(feature_flags.is_enabled("updater"))
	assert_eq(feature_flags.get_source("updater"), FeatureFlags.Source.DEFAULT)
	var offline := Feature.create("offline", false)
	feature_flags.register_feature(offline)
	assert_false(feature_flags.is_enabled("offline"))
	assert_false(feature_flags.is_enabled("nope"))
	assert_null(feature_flags.get_feature("nope"))


func test_normalizes_feature_ids() -> void:
	var feature := Feature.create("Steam_Deck Mode")
	assert_eq(feature.id, "steam-deck-mode")
	feature_flags.register_feature(feature)
	feature_flags.parse_args(["--feature-STEAM-DECK-MODE"])
	assert_true(feature_flags.is_enabled("Steam_Deck_Mode"))


func test_args_enable_and_disable() -> void:
	feature_flags.parse_args(["--feature-offline", "--feature-no-updater"])
	feature_flags.register_feature(Feature.create("offline", false))
	assert_true(feature_flags.is_enabled("offline"))
	assert_false(feature_flags.is_enabled("updater"))
	assert_eq(feature_flags.get_source("updater"), FeatureFlags.Source.ARG)


func test_env_bulk_lists() -> void:
	feature_flags.parse_env({
		"OGUI_FEATURES": "offline, steam-deck-mode",
		"OGUI_DISABLED_FEATURES": "updater",
	})
	feature_flags.register_feature(Feature.create("offline", false))
	feature_flags.register_feature(Feature.create("steam_deck_mode", false))
	assert_true(feature_flags.is_enabled("offline"))
	assert_true(feature_flags.is_enabled("steam-deck-mode"))
	assert_false(feature_flags.is_enabled("updater"))


func test_precedence() -> void:
	feature_flags.parse_env({"OGUI_FEATURE_UPDATER": "0"})
	assert_false(feature_flags.is_enabled("updater"))
	assert_eq(feature_flags.get_source("updater"), FeatureFlags.Source.ENV)
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


func test_signal_on_registration_when_overridden() -> void:
	feature_flags.parse_env({"OGUI_FEATURE_OFFLINE": "1"})
	var offline := Feature.create("offline", false)
	feature_flags.register_feature(offline)
	assert_signal_emitted_with_parameters(feature_flags, "feature_changed", [offline, true])

# Feature Flags

Feature flags are named boolean switches that can be turned on or off from the
command line, the environment, or at runtime by plugins and platform classes.
They are useful for enabling experimental features, disabling subsystems that do
not apply to a device, or letting a plugin opt into behavior.

Flags are managed by the
[FeatureFlags](../../class-reference/FeatureFlags.md) resource, which is shared
across the whole application. A single feature is described by a
[Feature](../../class-reference/Feature.md) resource containing its `id`,
`description`, and `default` state.

## Resolving a flag

The value of a feature is resolved from the first source that provides one:

1. A runtime override set with `set_feature()`
2. A command-line argument
3. An environment variable
4. The feature's `default`

Feature ids are normalized to lowercase with hyphens, so `Updater`, `updater`,
`UPDATER`, and `updater_mode` all refer to the same feature.

## Command line and environment

```bash
# Enable a feature
opengamepad-ui --feature-updater

# Disable a feature
opengamepad-ui --feature-no-updater

# Per-feature environment variable
OGUI_FEATURE_UPDATER=0 opengamepad-ui

# Bulk lists, comma or space separated
OGUI_FEATURES=offline,steam-deck-mode opengamepad-ui
OGUI_DISABLED_FEATURES=updater opengamepad-ui
```

Values are read as booleans: `1`, `true`, `yes`, and `on` enable a feature, and
`0`, `false`, `no`, and `off` disable it. The environment key for a feature is
derived from its id, so `steam-deck-mode` becomes `OGUI_FEATURE_STEAM_DECK_MODE`.

Bulk lists are applied before per-feature variables, so a per-feature variable
wins when both name the same feature. Values that are not boolean strings are
ignored and the feature keeps its default.

## Using flags in a plugin

Plugins can register their own features and read them anywhere in the codebase:

```gdscript
extends Plugin

var feature_flags := load("res://core/systems/features/feature_flags.tres") as FeatureFlags
var logger := Log.get_logger("MyPlugin")


func _ready() -> void:
	# Connect signals before registering, so a change emitted during registration is not missed.
	feature_flags.feature_changed.connect(_on_feature_changed)

	var feature := Feature.create("my-plugin-voice-chat", false, "Voice chat support")
	var err := feature_flags.register_feature(feature)
	if err == Error.ERR_ALREADY_EXISTS:
		# Another plugin owns this id already; use the registered feature instead of overriding it.
		feature = feature_flags.get_feature("my-plugin-voice-chat")
	elif err != Error.OK:
		logger.warn("Cannot register feature: " + str(err))
		return

	if feature_flags.is_enabled(feature.id):
		logger.info("Voice chat is enabled")


func _on_feature_changed(feature: Feature, enabled: bool) -> void:
	if feature.id != "my-plugin-voice-chat":
		return
	print("Voice chat is now ", "on" if enabled else "off")
```

`register_feature()` returns `Error`: `Error.OK` when the feature was newly
registered, `Error.ERR_INVALID_PARAMETER` when it has no id, and
`Error.ERR_ALREADY_EXISTS` when the id is already registered. It never replaces
an existing feature, so a duplicate registration leaves the first feature's
`default` in place.

## Unknown feature ids

Reading or setting an id that is not registered logs a warning and does nothing
else:

- `is_enabled()` warns and returns `false`
- `set_feature()` warns and returns without storing an override
- `get_feature()` returns `null`

Register the feature first, then read it. Warnings are written to the
`FeatureFlags` logger, so they can be raised or silenced with
`LOG_LEVEL_FEATUREFLAGS` (see the log level environment variables). The logger is
not created inside the editor, so warnings are skipped there.

## Signals

Signals are only emitted when the value actually changes. `feature_changed`
passes the `Feature` object, so handlers can read its `id`, `description`, and
`default` without a second lookup. `feature_enabled` and `feature_disabled` are
convenience signals for the two directions. `feature_registered` is emitted once
per successful registration.

## Sources and clearing

Use `feature_flags.get_source("my-plugin-voice-chat")` to find out which source
produced the current value. It returns one of `FeatureFlags.Source`
(`DEFAULT`, `ENV`, `ARG`, or `RUNTIME`).

Use `feature_flags.reset(id)` to drop a single runtime override so the feature
resolves from its sources again, or `feature_flags.clear_sources()` to drop every
parsed value at once.

`parse_args()` and `parse_env()` take explicit arguments instead of reading the
process, which makes them the entrypoints to use in tests; `load_from_os()` is the
convenience wrapper that reads the real command line and environment.

## Shared features

Features defined in `core/systems/features/feature_flags.tres` are available to
everything:

| id | default | behavior |
| --- | --- | --- |
| `updater` | `true` | Allows checking for and installing app updates. The settings menu hides its update section when it is off. |
| `tdp` | `true` | Allows managing TDP settings. |

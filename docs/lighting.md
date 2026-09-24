# Joystick lighting

The stock quick-settings menu includes lighting controls when InputPlumber
exposes LED API version 1. InputPlumber owns persistence and effects; closing OGUI
does not turn lighting off. Decky can configure the same settings independently.

The controls offer only advertised effects: Off, Solid, fixed-tempo hardware
Breathing, and Colour cycle. RGB is remembered for Solid/Breathing; cycle period
is 2–30 seconds and brightness is independent. Off preserves the other values.
Apply saves a complete configuration. The status distinguishes saved settings
from pending, applied, unavailable, and failed hardware state.

The shared LightingModel retains each identity's dirty draft and in-flight
request across quick-menu remounts. A backend notification updates clean drafts;
it never overwrites pending edits. A duplicate persistent identity is ambiguous
and cannot be configured. A missing/older backend leaves the rest of quick
settings usable.

Native LED resources use bounded asynchronous requests, unique D-Bus owner pins,
coalesced snapshots, PropertiesChanged notifications, and explicit reconnect.
No sysfs, private service, or effect loop exists in the frontend. Native signals
are deferred before GDScript reads a resource to avoid reentrant mutable borrows.
The API wire types are documented in the companion InputPlumber change.

## Verification

From extensions/, run:
```sh
cargo test --locked -p opengamepadui-core led -- --test-threads=1
cargo clippy --locked -p opengamepadui-core --all-targets
cargo build --locked --release
```

Use the project's GUT runner for
core/systems/input/lighting_model_test.gd. Require 12 collected tests, no failures
or skips, and no SCRIPT ERROR; a GUT process exit of zero alone is insufficient.
The tests cover lifecycle, multi-device isolation, stale replies, dirty drafts,
errors, capability controls, and stock quick-settings focus/scroll behavior.
lighting_render_test.gd renders fixture panels without a physical LED device.
Native tests start a private bus and fake services.

The pinned Godot 4.7.1 baseline also needs the independent install-dialog
scroll_maximum_size compatibility fix before a clean application export.
Existing upstream Rust lint findings are documented separately in the review
handoff; this change does not suppress them. Physical controller interaction,
visible LED output, and real session permissions require device validation.

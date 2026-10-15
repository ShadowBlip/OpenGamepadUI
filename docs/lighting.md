# Joystick lighting

The stock quick-settings menu includes lighting controls when InputPlumber
exposes LED API version 1. InputPlumber owns persistence and effects; closing OGUI
does not turn lighting off. Decky can configure the same settings independently.

The controls offer only advertised effects: Off, Solid, fixed-tempo hardware
Breathing, and Rainbow (the API's `cycle` effect). RGB is remembered for Solid/Breathing and brightness
is independent. Native cycling has fixed tempo: both cycle bounds are zero and
the panel shows a fixed-speed note instead of a slider. Software-capable devices
offer a 2–30 second period. The saved period remains unchanged on native hardware;
Off preserves the other values.
Apply saves a complete configuration. The status distinguishes saved settings
from unconfigured, pending, applied, unavailable, and failed hardware state.
An unconfigured device has no saved selection. Opening or closing the panel
leaves its existing lighting untouched; the placeholder Off value is applied
only after an explicit user request.

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
core/systems/input/lighting_model_test.gd. Require 14 collected tests, no failures
or skips, and no SCRIPT ERROR; a GUT process exit of zero alone is insufficient.
The tests cover lifecycle, multi-device isolation, stale replies, dirty drafts,
errors, capability controls, and stock quick-settings focus/scroll behavior.
lighting_render_test.gd renders fixture panels without a physical LED device.
Native tests start a private bus and fake services.

The branch includes regression tests for the install-dialog compatibility fix
already present in the current Godot 4.7.1 baseline.
Existing upstream Rust lint findings are documented separately in the review
handoff; this change does not suppress them. Physical controller interaction,
visible LED output, and real session permissions require device validation.

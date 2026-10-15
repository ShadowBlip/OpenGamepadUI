# Fan profiles

The Fan Settings quick-menu card requires PowerStation fan API v2, including
its startup-status and guarded startup-load methods. API v1 clients and
PowerStation releases without this contract cannot be used for these controls.
CPU/GPU controls retain their existing contracts.

PowerStation enumerates stable fan and sensor IDs. The card shows each fan's
current mode, advertised editable modes and sensor temperatures. A percentage
is displayed only when `PercentValid` is true; firmware Automatic/native curves
can have valid temperature telemetry while duty is unavailable. RPM, raw PWM,
driver settings, ownership and thermal-policy values are not client controls.

- **Automatic:** firmware controls cooling.
- **Manual:** request a fixed percentage, subject to the service's safety policy.
- **Software curve:** PowerStation interpolates the selected sensors' curve.
- **Firmware curve:** the hardware runs the complete native curve. Its current
  duty is unavailable through this API.

Choose a mode and percentage or edit the complete profile as JSON, then Apply
and save. Each enumerated fan must appear exactly once. Curve entries name
sensors and supply increasing temperature/percentage pairs. Native firmware
curves require the exact hardware point count; the service rejects incomplete
curves and enforces its own safety policy without resampling. Selecting a mode
or editing a draft does not write hardware. Firmware Automatic is a separate
explicit action that remains usable without telemetry or a valid saved draft.

For example, after substituting the IDs advertised on the current system:

```json
{
  "name": "My curve",
  "fans": [{
    "fan": "ayaneo-3/system",
    "mode": "software_curve",
    "sensors": ["ayaneo-3/system/cpu"],
    "curve": [[45, 20], [65, 40], [85, 70], [95, 100]]
  }]
}
```

Load and save file profile calls `LoadProfile` with a filename, such as the
packaged `quiet.yaml`. PowerStation resolves only its approved profile
directories; a same-name distro override replaces the whole packaged profile.
A saved file selection stores that reference, so a later explicit or guarded
load uses the current distro version. The JSON editor remains a separate draft;
a file profile's curve is not guessed from telemetry.

## Preferences and restoration

OpenGamepadUI owns `user://data/fans/profile.json`, a versioned, bounded private
JSON preference file. Only a successful, owner-pinned service reply permits
saving a selection. Writes are synced and atomically renamed. Save errors are
reported even when the hardware request succeeded. Corrupt, oversized, linked
or insecure existing preferences are preserved and reported, never reset.
PowerStation remains the authority for all profile and hardware validation.

Every new PowerStation process starts in firmware Automatic. At application
startup, OpenGamepadUI reads native `GetStartupStatus`, checks the kernel boot
identity and durably consumes its per-user boot attempt before reading saved
preferences or sending a restoration request. No saved selection means no
hardware write. `LoadStartupProfile`/`LoadStartupProfileJson` recheck the first
managed invocation and healthy untouched Automatic state under the native
profile transaction lock. A status read cannot authorize a stale later write.

The client pins the unique D-Bus owner for snapshots and requests. Ineligible
startup, service replacement, faults, invalid telemetry, a previously selected
profile, malformed preferences, failed/uncertain requests and a consumed boot
attempt prevent automatic replay. Refreshing/remounting the menu never restores
anything. Application/service restarts within that boot do not retry. Successful
suspend/resume remains the native service's responsibility. A user can always
select a fresh profile explicitly after reviewing current state.

The per-user attempt directories are preferences-side evidence, not privileged
ownership. The native transaction guard is authoritative across clients. Do not
delete startup evidence to manufacture eligibility. If repairing corrupt user
preferences manually, preserve the `restore-*` attempt directories.

## Validation

Run the `fan_` Rust tests with a private `dbus-daemon`, the focused GUT
`fan_profile_model_test.gd` and `fan_controls_menu_test.gd` suites, and locked
release builds for x86_64 and aarch64 in the pinned project builder. Fake
services/files prove software behavior only. Native GUI interaction, installed
session permissions and physical fan/thermal behavior on this revision require
separate device acceptance. See the PR handoff for exact tested commits and
counts.

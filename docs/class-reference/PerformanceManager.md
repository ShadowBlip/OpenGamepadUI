# PerformanceManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Manages, sets, and loads performance profiles
## Description

The PerformanceManager is responsible for applying the appropriate performance profile when games launch and when the device is plugged in or unplugged.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [UPowerDevice](../UPowerDevice) | [display_device](./#display_device) | <unknown> |
| [PerformanceProfile](../PerformanceProfile) | [current_profile](./#current_profile) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [current_profile_state](./#current_profile_state) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_profile_filename](./#get_profile_filename)(profile_state: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), library_item: [LibraryLaunchItem](../LibraryLaunchItem) = null) |
| void | [save_profile](./#save_profile)(profile: [PerformanceProfile](../PerformanceProfile), profile_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), library_item: [LibraryLaunchItem](../LibraryLaunchItem) = null) |
| [PerformanceProfile](../PerformanceProfile) | [create_profile](./#create_profile)(library_item: [LibraryLaunchItem](../LibraryLaunchItem) = null) |
| [PerformanceProfile](../PerformanceProfile) | [load_profile](./#load_profile)(profile_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [PerformanceProfile](../PerformanceProfile) | [load_or_create_profile](./#load_or_create_profile)(profile_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), library_item: [LibraryLaunchItem](../LibraryLaunchItem) = null) |
| void | [apply_profile](./#apply_profile)(profile: [PerformanceProfile](../PerformanceProfile)) |
| void | [apply_and_save_profile](./#apply_and_save_profile)(profile: [PerformanceProfile](../PerformanceProfile)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_profile_state](./#get_profile_state)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_profile_state_from_battery](./#get_profile_state_from_battery)(battery: [UPowerDevice](../UPowerDevice)) |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_power_profiles_available](./#get_power_profiles_available)() |


------------------

## Property Descriptions

### `display_device`


[UPowerDevice](../UPowerDevice) display_device


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `current_profile`


[PerformanceProfile](../PerformanceProfile) current_profile


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `current_profile_state`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) current_profile_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_profile_filename()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_profile_filename**(profile_state: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), library_item: [LibraryLaunchItem](../LibraryLaunchItem) = null)


Returns a profile filename generated from the given profile state and library item. E.g. "Bravo_15_A4DDR_docked_default_profile.tres"
### `save_profile()`


void **save_profile**(profile: [PerformanceProfile](../PerformanceProfile), profile_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), library_item: [LibraryLaunchItem](../LibraryLaunchItem) = null)


Saves the given PerformanceProfile to the given path. If a library item is passed, the user's settings will be updated to use the given profile.
### `create_profile()`


[PerformanceProfile](../PerformanceProfile) **create_profile**(library_item: [LibraryLaunchItem](../LibraryLaunchItem) = null)


Create a new [PerformanceProfile](../PerformanceProfile) from the current performance settings. If a library item is passed, the profile will be named after the library item.
### `load_profile()`


[PerformanceProfile](../PerformanceProfile) **load_profile**(profile_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Loads a PerformanceProfile from the given path. Returns null if the profile fails to load.
### `load_or_create_profile()`


[PerformanceProfile](../PerformanceProfile) **load_or_create_profile**(profile_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), library_item: [LibraryLaunchItem](../LibraryLaunchItem) = null)


Loads a PerformanceProfile from the given path. If the profile does not exist, it will create a new profile using the currently applied performance settings.
### `apply_profile()`


void **apply_profile**(profile: [PerformanceProfile](../PerformanceProfile))


Applies the given performance profile to the system
### `apply_and_save_profile()`


void **apply_and_save_profile**(profile: [PerformanceProfile](../PerformanceProfile))


Applies the given performance profile to the system and saves it based on the current profile state (e.g. docked or undocked) and current running app.
### `get_profile_state()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_profile_state**()


Returns the current profile state. I.e. whether or not the "docked" or "undocked" performance profiles should be used.
### `get_profile_state_from_battery()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_profile_state_from_battery**(battery: [UPowerDevice](../UPowerDevice))


Returns the current profile state. I.e. whether or not the "docked" or "undocked" performance profiles should be used.
### `get_power_profiles_available()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_power_profiles_available**()


!!! note
    There is currently no description for this method. Please help us by contributing one!


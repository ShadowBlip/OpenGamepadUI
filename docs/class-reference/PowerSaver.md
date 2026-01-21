# PowerSaver

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

TODO: Use inputmanager to send power_save events for every input!!
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [DisplayManager](../DisplayManager) | [display](./#display) | <unknown> |
| [SettingsManager](../SettingsManager) | [settings](./#settings) | <unknown> |
| [UPowerInstance](../UPowerInstance) | [power_manager](./#power_manager) | <unknown> |
| [GamescopeInstance](../GamescopeInstance) | [gamescope](./#gamescope) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [dim_screen_enabled](./#dim_screen_enabled) | true |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [dim_after_inactivity_mins](./#dim_after_inactivity_mins) | 5 |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [dim_percent](./#dim_percent) | 10 |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [dim_when_charging](./#dim_when_charging) | true |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [auto_suspend_enabled](./#auto_suspend_enabled) | true |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [suspend_after_inactivity_mins](./#suspend_after_inactivity_mins) | 20 |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [suspend_when_charging](./#suspend_when_charging) | false |
| [Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html) | [dim_timer](./#dim_timer) | <unknown> |
| [Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html) | [suspend_timer](./#suspend_timer) | <unknown> |
| [Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html) | [gamescope_timer](./#gamescope_timer) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [dimmed](./#dimmed) | false |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [prev_brightness](./#prev_brightness) | {} |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [supports_brightness](./#supports_brightness) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_battery](./#has_battery) | false |
| [UPowerDevice](../UPowerDevice) | [display_device](./#display_device) | <unknown> |
| [Dictionary[int, int]](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [gamescope_input_counters](./#gamescope_input_counters) | {} |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |



------------------

## Property Descriptions

### `display`


[DisplayManager](../DisplayManager) display


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `settings`


[SettingsManager](../SettingsManager) settings


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `power_manager`


[UPowerInstance](../UPowerInstance) power_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `gamescope`


[GamescopeInstance](../GamescopeInstance) gamescope


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dim_screen_enabled`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) dim_screen_enabled = <span style="color: red;">true</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dim_after_inactivity_mins`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) dim_after_inactivity_mins = <span style="color: red;">5</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dim_percent`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) dim_percent = <span style="color: red;">10</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dim_when_charging`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) dim_when_charging = <span style="color: red;">true</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `auto_suspend_enabled`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) auto_suspend_enabled = <span style="color: red;">true</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `suspend_after_inactivity_mins`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) suspend_after_inactivity_mins = <span style="color: red;">20</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `suspend_when_charging`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) suspend_when_charging = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dim_timer`


[Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html) dim_timer


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `suspend_timer`


[Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html) suspend_timer


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `gamescope_timer`


[Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html) gamescope_timer


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dimmed`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) dimmed = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `prev_brightness`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) prev_brightness = <span style="color: red;">{}</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `supports_brightness`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) supports_brightness


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `has_battery`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) has_battery = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `display_device`


[UPowerDevice](../UPowerDevice) display_device


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `gamescope_input_counters`


[Dictionary[int, int]](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) gamescope_input_counters = <span style="color: red;">{}</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!



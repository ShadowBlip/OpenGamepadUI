# DRMCardInfoAMD

**Inherits:** [DRMCardInfo](../DRMCardInfo)


## Methods

| Returns | Signature |
| ------- | --------- |
| [Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html) | [get_clock_limits](./#get_clock_limits)() |
| [Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html) | [get_clock_values](./#get_clock_values)() |


------------------

## Method Descriptions

### `get_clock_limits()`


[Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html) **get_clock_limits**()


Reads the pp_od_clk_voltage from sysfs and returns the OD_RANGE values. This file will be empty if not in "manual" for pp_od_performance_level.
### `get_clock_values()`


[Vector2](https://docs.godotengine.org/en/stable/classes/class_vector2.html) **get_clock_values**()


Reads the pp_od_clk_voltage from sysfs and returns the OD_SCLK values. This file will be empty if not in "manual" for pp_od_performance_level.

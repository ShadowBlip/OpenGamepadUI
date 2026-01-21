# SteamRemovableMediaManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [UDisks2Instance](../UDisks2Instance) | [udisks2](./#udisks2) | <unknown> |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [block_operations](./#block_operations) | false |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [format_capable](./#format_capable) | false |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [init_capable](./#init_capable) | false |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [format_sd_capable](./#format_sd_capable) | false |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [retrigger_capable](./#retrigger_capable) | false |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [trim_capable](./#trim_capable) | false |

## Methods

| Returns | Signature |
| ------- | --------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [format_drive](./#format_drive)(device: [BlockDevice](../BlockDevice)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [init_steam_lib](./#init_steam_lib)(partition: [PartitionDevice](../PartitionDevice)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [retrigger_automounts](./#retrigger_automounts)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [format_sd_card](./#format_sd_card)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [trim_sd_card](./#trim_sd_card)() |


------------------

## Property Descriptions

### `udisks2`


[UDisks2Instance](../UDisks2Instance) udisks2


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `block_operations`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) block_operations = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `format_capable`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) format_capable = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `init_capable`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) init_capable = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `format_sd_capable`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) format_sd_capable = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `retrigger_capable`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) retrigger_capable = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `trim_capable`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) trim_capable = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `format_drive()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **format_drive**(device: [BlockDevice](../BlockDevice))


Calls the SteamRemovableMedia format-media script to format a drive as EXT4 and intialize it as a steam library
### `init_steam_lib()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **init_steam_lib**(partition: [PartitionDevice](../PartitionDevice))


Calls the SteamRemovableMedia init-media script to intialize a drive as a steam library
### `retrigger_automounts()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **retrigger_automounts**()


Calls the SteamRemovableMedia or SteamOS retrigger-automounts script to restart all the media-mount@ scripts.
### `format_sd_card()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **format_sd_card**()


Calls the SteamRemovableMedia or SteamOS format-sd script to format mmcblk0 as EXT4 and intialize it as a steam library
### `trim_sd_card()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **trim_sd_card**()


Calls the SteamRemovableMedia or SteamOS trim-devices script to perform a trim operation on mmcblk0.

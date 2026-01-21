# WifiNetworkTree

**Inherits:** [Tree](https://docs.godotengine.org/en/stable/classes/class_tree.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [NetworkManagerInstance](../NetworkManagerInstance) | [network_manager](./#network_manager) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [connecting](./#connecting) | false |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [network_connect](./#network_connect)(password: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), ssid: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [refresh_networks](./#refresh_networks)() |


------------------

## Property Descriptions

### `network_manager`


[NetworkManagerInstance](../NetworkManagerInstance) network_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `connecting`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) connecting = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `network_connect()`


void **network_connect**(password: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), ssid: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Connect to the given wireless network
### `refresh_networks()`


void **refresh_networks**()


Refreshes the available wifi networks

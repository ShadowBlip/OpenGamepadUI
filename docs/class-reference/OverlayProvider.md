# OverlayProvider

**Inherits:** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html)

Base class to use when writing a new overlay.
## Description

An [OverlayProvider](../OverlayProvider) is a [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) node that is meant to work as an overlay. To write a new overlay, create a new class that extends from this one.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [provider_id](./#provider_id) |  |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [icon](./#icon) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [managed](./#managed) | true |
| [CustomLogger](../CustomLogger) | [logger](./#logger) |  |



------------------

## Property Descriptions

### `provider_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) provider_id


Unique identifier for the overlay provider
### `icon`


[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) icon


Icon associated with the overlay provider
### `managed`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) managed = <span style="color: red;">true</span>


Whether or not the overlay's layout should be managed by an [OverlayContainer](../OverlayContainer)
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!



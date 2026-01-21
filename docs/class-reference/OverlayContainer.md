# OverlayContainer

**Inherits:** [Container](https://docs.godotengine.org/en/stable/classes/class_container.html)

Manages the layout for multiple [OverlayProvider](../OverlayProvider) nodes.
## Description

The [OverlayContainer](../OverlayContainer) is meant to be added to the main UI scene to provide a place to add an arbitrary number of [OverlayProvider](../OverlayProvider) nodes and manage their layout and ordering.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [overlays](./#overlays) | {} |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [add_overlay](./#add_overlay)(overlay: [OverlayProvider](../OverlayProvider)) |
| void | [remove_overlay](./#remove_overlay)(overlay: [OverlayProvider](../OverlayProvider)) |


------------------

## Property Descriptions

### `overlays`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) overlays = <span style="color: red;">{}</span>


Dictionary of {provider_id: <[OverlayProvider](../OverlayProvider)>}.
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `add_overlay()`


void **add_overlay**(overlay: [OverlayProvider](../OverlayProvider))


Add the given overlay to the overlay container
### `remove_overlay()`


void **remove_overlay**(overlay: [OverlayProvider](../OverlayProvider))


Remove the given overlay from the overlay container.

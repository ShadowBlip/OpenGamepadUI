# BoxArtManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Fetch and manage artwork from registered [BoxArtProvider](../BoxArtProvider) nodes
## Description

The BoxArtManager is responsible for managing any number of [BoxArtProvider](../BoxArtProvider) nodes and providing a unified way to fetch box art from multiple sources to any systems that might need them. New box art sources can be created in the core code base or in plugins by implementing/extending the [BoxArtProvider](../BoxArtProvider) class and adding them to the scene.

With registered box art providers, other systems can request box art from the BoxArtManager, and it will use all available sources to return the best artwork:
```gdscript

    const BoxArtManager := preload("res://core/global/boxart_manager.tres")
    ...
    var boxart := BoxArtManager.get_boxart(library_item, BoxArtProvider.LAYOUT.LOGO)

```


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [get_boxart](./#get_boxart)(item: [LibraryItem](../LibraryItem), kind: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [get_boxart_or_placeholder](./#get_boxart_or_placeholder)(item: [LibraryItem](../LibraryItem), kind: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [get_placeholder](./#get_placeholder)(kind: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [BoxArtProvider](../BoxArtProvider) | [get_provider_by_id](./#get_provider_by_id)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) | [get_providers](./#get_providers)() |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) | [get_provider_ids](./#get_provider_ids)() |
| void | [register_provider](./#register_provider)(provider: [BoxArtProvider](../BoxArtProvider)) |
| void | [unregister_provider](./#unregister_provider)(provider: [BoxArtProvider](../BoxArtProvider)) |


------------------

## Property Descriptions

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_boxart()`


[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) **get_boxart**(item: [LibraryItem](../LibraryItem), kind: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns the boxart of the given kind for the given library item.
### `get_boxart_or_placeholder()`


[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) **get_boxart_or_placeholder**(item: [LibraryItem](../LibraryItem), kind: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns the boxart of the given kind for the given library item. If one is not found, a placeholder texture will be returned
### `get_placeholder()`


[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) **get_placeholder**(kind: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns a boxart placeholder for the given layout
### `get_provider_by_id()`


[BoxArtProvider](../BoxArtProvider) **get_provider_by_id**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the given boxart implementation by id
### `get_providers()`


[Array](https://docs.godotengine.org/en/stable/classes/class_array.html) **get_providers**()


Returns a list of all registered boxart providers
### `get_provider_ids()`


[Array](https://docs.godotengine.org/en/stable/classes/class_array.html) **get_provider_ids**()


Returns a list of all registered boxart provider ids
### `register_provider()`


void **register_provider**(provider: [BoxArtProvider](../BoxArtProvider))


Registers the given boxart provider with the boxart manager.
### `unregister_provider()`


void **unregister_provider**(provider: [BoxArtProvider](../BoxArtProvider))


Unregisters the given boxart provider

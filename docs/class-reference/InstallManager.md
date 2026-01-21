# InstallManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [InstallManager.Request](../InstallManager.Request) | [get_installing](./#get_installing)() |
| void | [install](./#install)(request: [InstallManager.Request](../InstallManager.Request)) |
| void | [update](./#update)(request: [InstallManager.Request](../InstallManager.Request)) |
| void | [uninstall](./#uninstall)(request: [InstallManager.Request](../InstallManager.Request)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_queued](./#is_queued)(item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_installing](./#is_installing)(item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_queued_or_installing](./#is_queued_or_installing)(item: [LibraryLaunchItem](../LibraryLaunchItem)) |


------------------

## Property Descriptions

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_installing()`


[InstallManager.Request](../InstallManager.Request) **get_installing**()


Returns the currently processing install request
### `install()`


void **install**(request: [InstallManager.Request](../InstallManager.Request))


Installs the given library launch item using its provider
### `update()`


void **update**(request: [InstallManager.Request](../InstallManager.Request))


Updates the given library launch item using its provider
### `uninstall()`


void **uninstall**(request: [InstallManager.Request](../InstallManager.Request))


Uninstalls the given library launch item using its provider
### `is_queued()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_queued**(item: [LibraryLaunchItem](../LibraryLaunchItem))


Returns whether or not the given launch item is queued for install
### `is_installing()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_installing**(item: [LibraryLaunchItem](../LibraryLaunchItem))


Returns whether or not the given launch item is currently being installed
### `is_queued_or_installing()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_queued_or_installing**(item: [LibraryLaunchItem](../LibraryLaunchItem))


Returns whether or not the given launch item is being installed or queued for install.

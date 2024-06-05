extends Resource
class_name LibraryRefreshState

## State for signaling when the library is refreshing
##
## This class provides a shared resource that can be used to monitor library
## refreshes between different UI components.

## Emitted when the UI has started refreshing the library menu
signal refresh_started
## Emitted when the UI has finished refreshing the library menu
signal refresh_completed

var is_refreshing := false

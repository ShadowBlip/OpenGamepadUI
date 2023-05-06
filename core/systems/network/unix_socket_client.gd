@icon("res://assets/editor-icons/socket-bold.svg")
extends Node
class_name UnixSocketClient

signal connected
signal data
signal disconnected
signal error

var _is_open: bool = false
var _stream := StreamPeerUnix.new()
var _logger := Log.get_logger("UnixSocketClient")


func _ready() -> void:
	_is_open = _stream.is_open()


func _process(_delta: float) -> void:
	var new_status := _stream.is_open()
	if new_status != _is_open:
		var prev_status := _is_open
		_is_open = new_status
		if prev_status and not new_status:
			_logger.info("Disconnected from socket.")
			disconnected.emit()
		if new_status:
			_logger.info("Connected to socket.")
			connected.emit()

	if _is_open:
		var available_bytes: int = _stream.get_available_bytes()
		if available_bytes > 0:
			_logger.debug("available bytes: " + str(available_bytes))
			var parts := _stream.get_partial_data(available_bytes)
			# Check for read error.
			if parts[0] != OK:
				_logger.error("Error getting data from stream: " + str(parts[0]))
				error.emit()
			else:
				data.emit(parts[1])


func open(path: String) -> void:
	# Reset status so we can tell if it changes to error again.
	_is_open = false
	if _stream.open(path) != OK:
		error.emit()


func send(data: PackedByteArray) -> bool:
	if not _is_open:
		_logger.error("Error: Stream is not currently connected.")
		return false
	var err: int = _stream.put_data(data)
	if err != OK:
		_logger.error("Error writing to stream: " + str(err))
		return false
	return true

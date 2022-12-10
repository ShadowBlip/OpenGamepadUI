extends Node
class_name WebsocketRPCClient

signal socket_connected()
signal socket_closed()
signal request_completed(status: int, data: Variant)

var socket := WebSocketPeer.new()
var connected := false
var logger := Log.get_logger("WebsocketRPCClient")

# Open a websocket connection with the given URL
func open(url: String = "ws://localhost:5000") -> int:
	var status := socket.connect_to_url(url)
	set_process(true)
	return status


# Close the websocket connection
func close():
	socket.close()


# Make an RPC request to the websocket server
func make_request(method: String, args: Array) -> Variant:
	logger.debug("Making RPC request: {0}".format([method]))
	var id := UUID.v4()
	var rpc := JSONRPC.new()
	var req := rpc.make_request(method, args, id)
	if socket.send_text(JSON.stringify(req)) != OK:
		logger.error("Failed to send RPC message")
		return null
	var response: Array = await request_completed
	var data: Variant = response[1]
	return data


# Polls the socket every frame for data
func _process(delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not connected:
			connected = true
			socket_connected.emit()
		while socket.get_available_packet_count():
			_process_response(socket.get_packet())
		return
	if state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		return
	if state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		socket_closed.emit()
		logger.debug("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.


func _process_response(data: PackedByteArray) -> void:
	var response_str := data.get_string_from_utf8()
	var response: Dictionary = JSON.parse_string(response_str)
	if "error" in response:
		logger.error("Got error response: " + response["error"]["message"])
		request_completed.emit(FAILED, null)
		return
	if "result" in response:
		request_completed.emit(OK, response["result"])
		return
	request_completed.emit(OK, null)

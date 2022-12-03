extends Node
class_name MultiHTTPRequest

signal request_completed(results: Array)
signal worker_done(worker: int)

@export var num_clients: int = 8

var _clients: Array = []
var _requests: Array = []
var _requests_queue: Array = []
var _responses_queue: Array = []
var _done: Array = []
var logger := Log.get_logger("MultiHTTPRequest")


func _ready() -> void:
	worker_done.connect(_on_worker_done)
	for i in range(0, num_clients):
		var client: HTTPRequest = HTTPRequest.new()
		client.use_threads = true
		add_child(client)
		
		# Build the work queue and results queues
		_requests_queue.push_back([])
		_responses_queue.push_back([])
		_done.push_back(false)
		_clients.push_back(client)
		client.request_completed.connect(_http_request_completed.bind(i))


func _http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, worker: int) -> void:
	# Push the response
	logger.debug("Worker {0} got response: {1}".format([worker, response_code]))
	var response: Dictionary = {
		"result": result,
		"response_code": response_code,
		"headers": headers,
		"body": body,
	}
	_responses_queue[worker].push_back(response)
	
	# Pop the item off the queue
	logger.debug("Worker {0} done".format([worker]))
	_requests_queue[worker].pop_front()
	
	# If we don't have more work, emit completed
	if len(_requests_queue[worker]) == 0:
		worker_done.emit(worker)
		logger.debug("ALL WORK DONE!")
		return
	
	# Continue working on our queue
	var client: HTTPRequest = _clients[worker]
	client.request(_requests_queue[worker][0])


func _on_worker_done(worker: int):
	_done[worker] = true
	
	# If any worker is not done, do nothing
	for done in _done:
		if not done:
			return
	
	logger.debug("ALL WORKERS ARE DONE!")
	_collect_results()


# Collects the results from each worker and emits them all.
func _collect_results() -> void:
	var results: Array = []
	var i: int = 0
	for url in _requests:
		var worker = i % num_clients
		if len(_responses_queue[worker]) == 0:
			continue
		var res: Dictionary = _responses_queue[worker].pop_front()
		results.push_back(res)
		i += 1
	
	request_completed.emit(results)
	_reset_queues()


# Cancels any pending requests and empties our queues
func cancel_request() -> void:
	for c in _clients:
		var client: HTTPRequest = c
		client.cancel_request()
	_reset_queues()
	

# Empties all queues and requests
func _reset_queues() -> void:
	for i in range(0, num_clients):
		_requests = []
		_requests_queue[i] = []
		_responses_queue[i] = []
		_done[i] = false


# Dispatch multiple HTTP clients to fetch the given URLs
func request(urls: PackedStringArray) -> int:
	# If we still have work to do, error out
	for queue in _requests_queue:
		if len(queue) > 0:
			return HTTPClient.STATUS_REQUESTING
	
	# Distribute the work to the clients
	var i: int = 0
	for url in urls:
		_requests.push_back(url)
		var worker = i % num_clients
		_requests_queue[worker].push_back(url)
		logger.debug("URL {0} goes to worker {1}".format([url, worker]))
		i += 1
		
	# Start their work on their queues
	for worker in range(0, len(_clients)):
		if len(_requests_queue[worker]) == 0:
			worker_done.emit(worker)
			continue
		var client: HTTPRequest = _clients[worker]
		var err = client.request(_requests_queue[worker][0])
		if err != OK:
			return err
		
	return OK

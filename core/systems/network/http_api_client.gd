extends Node
class_name HTTPAPIClient

@export var base_url := ""
@export var headers := PackedStringArray()
@export var cache_folder := "HTTPAPIClient"
@export var verify_tls := true
var logger := Log.get_logger("HTTPAPIClient")


func request(
	path: String,
	caching_flags: int = Cache.FLAGS.LOAD | Cache.FLAGS.SAVE,
	xtra_headers: PackedStringArray = [],
	method: HTTPClient.Method = 0,
	data: String = ""
) -> Response:
	# Build the URL and headers
	if base_url.ends_with("/"):
		base_url = base_url.trim_suffix("/")
	if path.begins_with("/"):
		path = path.trim_prefix("/")
	var url := "/".join([base_url, path])
	var hdrs := headers.duplicate()
	hdrs.append_array(xtra_headers)
	logger.debug(url)

	# Check if this item is already cached
	var cache_key := path + ",".join(hdrs) + data + str(method)
	if caching_flags & Cache.FLAGS.LOAD and Cache.is_cached(cache_folder, cache_key):
		logger.debug("Found cached result")
		var cached = Cache.get_json(cache_folder, cache_key) as Array
		return Response.from_cached_result(cached)

	# Make the request
	var http := HTTPRequest.new()
	if not verify_tls:
		http.set_tls_options(TLSOptions.client_unsafe())
	http.timeout = 30.0
	add_child.call_deferred(http)
	await http.ready
	var err := http.request(url, hdrs, method, data)
	if err != OK:
		logger.warn("Unable to query API: " + str(err))
		http.queue_free()
		return null

	# Wait for the response
	var results := await http.request_completed as Array

	# Build the response
	var response := Response.new()
	response.result = results[0]
	response.code = results[1]
	response.header = results[2]
	response.body = results[3]

	# Cache the result
	if response.result == OK and response.code < 300 and caching_flags & Cache.FLAGS.SAVE:
		var to_cache := results.duplicate()
		var b64data := Marshalls.raw_to_base64(results[3])
		to_cache[3] = b64data
		Cache.save_json(cache_folder, cache_key, to_cache)

	http.queue_free()
	return response


class Response:
	var result: int
	var code: int
	var header: PackedStringArray
	var body: PackedByteArray

	# Returns the JSON decoded body. Returns null if parse error.
	func get_json() -> Variant:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) != OK:
			return null
		return json.get_data()

	static func from_cached_result(result: Array) -> Response:
		var res := Response.new()
		res.result = result[0]
		res.code = result[1]
		res.header = result[2]
		res.body = Marshalls.base64_to_raw(result[3])
		return res

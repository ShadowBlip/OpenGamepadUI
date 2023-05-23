extends Resource

## VDF Parsing
##
## References:
## https://github.com/ValvePython/vdf/blob/master/vdf/__init__.py
## https://developer.valvesoftware.com/wiki/KeyValues

enum {
	OK,
	ERR_CANT_COMPILE_REGEX,
	ERR_EXPECTED_BRACKET,
	ERR_TOO_MANY_CLOSING_BRACKETS,
	ERR_UNEXPECTED_EOF,
}

var _stack := [{}]
var _expect_bracket := false
var _regex_kv = RegEx.new()
var _pattern = (
	'^("(?P<qkey>(?:\\\\.|[^\\\\"])*)"|(?P<key>#?[a-z0-9\\-\\_\\\\\\?$%<>]+))'
	+ "([ \\t]*("
	+ '"(?P<qval>(?:\\\\.|[^\\\\"])*)(?P<vq_end>")?'
	+ "|(?P<val>(?:(?<!/)/(?!/)|[a-z0-9\\-\\_\\\\\\?\\*\\.$<> ])+)"
	+ "|(?P<sblock>{[ \\t]*)(?P<eblock>})?"
	+ "))?"
)
var _err := OK
var _err_line := -1


func get_error_line() -> int:
	return _err_line


func get_error_message() -> String:
	if _err == ERR_CANT_COMPILE_REGEX:
		return "Can't compile regex pattern to match"
	if _err == ERR_EXPECTED_BRACKET:
		return "Expected an opening bracket"
	if _err == ERR_TOO_MANY_CLOSING_BRACKETS:
		return "One too many closing brackets"
	if _err == ERR_UNEXPECTED_EOF:
		return "Unexpected EOF (open key quote?)"
	return ""


func get_data() -> Dictionary:
	if _stack.size() == 0:
		return {}
	return _stack[0]


func parse(data: String) -> int:
	if _regex_kv.compile(_pattern) != OK:
		return ERR_CANT_COMPILE_REGEX

	var lines := data.split("\n")
	for lineno in range(0, lines.size()):
		var line := lines[lineno]
		line = line.strip_edges()

		# Skip empty and comment lines
		if line == "" or line.begins_with("/"):
			continue

		# One level deeper
		if line.begins_with("{"):
			_expect_bracket = false
			continue

		if _expect_bracket:
			_err_line = lineno
			_err = ERR_EXPECTED_BRACKET
			return _err

		# One level back
		if line.begins_with("}"):
			if _stack.size() > 1:
				_stack.pop_back()
				continue
			_err_line = lineno
			_err = ERR_TOO_MANY_CLOSING_BRACKETS
			return _err

		# Parse key/value pairs
		var result := _regex_kv.search(line)
		if not result:
			_err_line = lineno
			_err = ERR_UNEXPECTED_EOF
			return _err

		var key := result.get_string("qkey")
		if key == "":
			key = result.get_string("key")
		var val := result.get_string("qval")
		if val == "":
			val = result.get_string("val")
			if val != "":
				val = val.strip_edges(false, true)

		# Find the number of words on the line
		var words := line.replace("\t", " ").split(" ", false)
		var num_words := words.size()

		# We have a key without a value means we go a level deeper
		if val == "" and num_words == 1:
			var d := {}
			_stack[-1][key] = d

			# Only expect a bracket if it's not already closed or
			# on the same line
			if result.get_string("eblock") == "":
				_stack.push_back(d)
				if result.get_string("sblock") == "":
					_expect_bracket = true
			continue

		# We've matched a simple key/value pair, map it to the last dict
		# in the stack
		_stack[-1][key] = val

	return OK

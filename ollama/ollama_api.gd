extends Node

var ip : String = "127.0.0.1"
var port : int = 11434 # by default is 11434, possibly customizable by ollama?

var known_models : Array = [] : 
	set(value):
		known_models = value
		models_updated.emit(value)

var current_model : Dictionary = {} :
	set(value):
		current_model = value
		model_changed.emit(value)

signal models_updated
signal model_changed

func _ready() -> void:
	ip = "192.168.0.107"
	await _pull_models()

func _create_ip_string(): return "http://" + ip + ":" + str(port)

func _pull_models():
	var url = _create_ip_string() + "/api/tags"
	var models : PackedByteArray = (await http_request(url, [], HTTPClient.METHOD_GET, ""))[3]
	known_models = JSON.parse_string(models.get_string_from_utf8()).get("models", [])

func http_request(ip : String = "", headers : PackedStringArray = [], method : HTTPClient.Method = HTTPClient.METHOD_GET, data : String = ""):
	var http := HTTPRequest.new()
	add_child(http)
	http.request(ip, headers, method, data)
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	return response

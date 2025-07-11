class_name OllamaChat extends Node

var chat_history : Dictionary = { "model": "", "messages": [] }
var chat_name : String = ""

var current_response : String = ""
var waiting_for_response : bool = false

var chunks = 0

signal response_started
signal response_finished (response : String)

func _to_string() -> String: 
	return JSON.stringify(chat_history)

func new_chat_history():
	chat_history = { "model": OllamaAPI.current_model.name, "messages": [] }

func _create_user_prompt(content : String):
	chat_history.model = OllamaAPI.current_model.name
	chat_history.messages.append({ "role": "user", "content": content})

func _add_assistant_prompt(data : Dictionary): 
	chat_history.messages.append(data)

func _prompt_ollama():
	var streamer := HTTPStreamer.new()
	add_child(streamer)
	current_response = ""
	
	chunks = 0
	
	waiting_for_response = true
	
	streamer.stream_recieved_chunk.connect(process_chunk.bind(streamer))
	
	streamer.run_request("http://" + OllamaAPI.ip, "/api/chat", OllamaAPI.port, self._to_string())

func process_chunk(chunk : PackedByteArray, streamer : HTTPStreamer):
	var data_string : String = chunk.get_string_from_utf8()
	var json_data : Dictionary = JSON.parse_string(data_string)
	if json_data.has("done") and json_data.has("message"):
		if chunks == 0:
			response_started.emit()
		chunks += 1
		var message : Dictionary = json_data.message
		var is_done : bool = json_data.done
		current_response += message.content
		
		if is_done:
			var final_data = json_data
			final_data["message"]["content"] = current_response
			_add_assistant_prompt(final_data)
			
			response_finished.emit(current_response)
			
			waiting_for_response = false

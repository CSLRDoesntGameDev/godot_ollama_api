class_name HTTPStreamer extends Node

var http_client := HTTPClient.new()

signal stream_recieved_chunk(chunk: PackedByteArray)

func run_request(url: String, subdomain: String, port: int, body: String):
	http_client.connect_to_host(url, port) # Use the provided port instead of OllamaAPI.port
	var err = 0
	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		http_client.poll()
		#print("Connecting...")
		await get_tree().process_frame # Reference the current node's tree

	assert(http_client.get_status() == HTTPClient.STATUS_CONNECTED) # Check if the connection was made successfully.

	var headers = [
		"User-Agent: %s" % Engine.get_version_info(),
		"Accept: */*"
	]

	err = http_client.request(HTTPClient.METHOD_POST, subdomain, headers, body)
	assert(err == OK)

	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		http_client.poll()
		#print("Requesting...")
		await get_tree().process_frame # Reference the current node's tree

	assert(http_client.get_status() == HTTPClient.STATUS_BODY or http_client.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.

	#print("response? ", http_client.has_response()) # Site might not have a response.

	if http_client.has_response():
		# If there is a response...

		headers = http_client.get_response_headers_as_dictionary() # Get response headers.
		#print("code: ", http_client.get_response_code()) # Show response code.
		#print("**headers:\\n", headers) # Show headers.

		# Getting the Body

		if http_client.is_response_chunked():
			pass
			# Does it use chunks?
			#print("Response is Chunked!")
		else:
			# Or just plain Content-Length
			var bl = http_client.get_response_body_length()
			#print("Response Length: ", bl)

		# This method works for both anyway

		var rb = PackedByteArray() # Array that will hold the data.

		while http_client.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http_client.poll()
			# Get a chunk.
			var chunk = http_client.read_response_body_chunk()
			if chunk.size() == 0:
				pass
				await get_tree().process_frame # Reference the current node's tree
			else:
				rb = rb + chunk # Append to read buffer.
				stream_recieved_chunk.emit(chunk)

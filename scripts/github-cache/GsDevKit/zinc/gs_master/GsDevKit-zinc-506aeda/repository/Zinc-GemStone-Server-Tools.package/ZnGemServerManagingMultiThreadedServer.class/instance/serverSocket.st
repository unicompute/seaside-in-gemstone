accessing
serverSocket
  "Return the server socket that I am using.
	Will be nil when I am not running"

	^ SessionTemps current
		at: #ZnGemServerManagingMultiThreadedServer_serverSocket
		ifAbsent:[]

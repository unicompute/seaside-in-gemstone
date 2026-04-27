private
releaseServerSocket
	"Release our server socket"

	(SessionTemps current
		at: #ZnGemServerManagingMultiThreadedServer_serverSocket
		ifAbsent:[]
	) ifNil:[ ^self ].

	self log debug: 'Releasing server socket'.
	(SessionTemps current at: #ZnGemServerManagingMultiThreadedServer_serverSocket) destroy.
	SessionTemps current
		at: #ZnGemServerManagingMultiThreadedServer_serverSocket
		put: nil

private
initializeServerSocket
	"Set up a new server socket and listen on it"

	self log debug: 'Initializing server socket'.

	"if I am committed, then do not persist server socket instance"
	SessionTemps current
		at: #ZnGemServerManagingMultiThreadedServer_serverSocket
		put: ( self bindingAddress
					ifNil: [ ZnNetworkingUtils serverSocketOn: self port ]
					ifNotNil: [ ZnNetworkingUtils serverSocketOn: self port interface: self bindingAddress ]).

	self log debug: 'Initialized server socket'

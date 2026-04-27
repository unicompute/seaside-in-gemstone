Extension { #name : 'ZnGemServerManagingMultiThreadedServer' }

{ #category : '*SeasideInGemStone-Compatibility' }
ZnGemServerManagingMultiThreadedServer >> initializeServerSocket [
	"Keep the listening socket in a transient wrapper.
	The GemStone Zinc SessionTemps variant can lose the socket and later send #isValid to nil."

	self log debug: 'Initializing server socket'.
	self _setNoStubbing.
	serverSocket := TransientStackValue
		value: (self bindingAddress
			ifNil: [ ZnNetworkingUtils serverSocketOn: self port ]
			ifNotNil: [ ZnNetworkingUtils serverSocketOn: self port interface: self bindingAddress ]).
	self log debug: 'Initialized server socket'
]

{ #category : '*SeasideInGemStone-Compatibility' }
ZnGemServerManagingMultiThreadedServer >> releaseServerSocket [
	serverSocket ifNil: [ ^ self ].
	serverSocket value ifNil: [ ^ self ].
	self log debug: 'Releasing server socket'.
	serverSocket value destroy.
	serverSocket := nil
]

{ #category : '*SeasideInGemStone-Compatibility' }
ZnGemServerManagingMultiThreadedServer >> serverSocket [
	"Answer the transient wrapper expected by #serveConnectionsOn:."

	^ serverSocket
]

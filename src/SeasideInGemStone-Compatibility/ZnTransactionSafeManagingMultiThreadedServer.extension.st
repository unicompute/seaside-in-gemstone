Extension { #name : 'ZnTransactionSafeManagingMultiThreadedServer' }

{ #category : '*SeasideInGemStone-Compatibility' }
ZnTransactionSafeManagingMultiThreadedServer >> closeConnections [
	(self connections isNil or: [ self connections isEmpty ]) ifTrue: [ ^ self ].
	self log debug: [ 'Closing ', self connections size printString, ' connections' ].
	self lock critical: [
		self connections do: [ :each |
			self log debug: [ 'Closing ', each printString ].
			[ each close ]
				on: Error
				do: [ :exception |
					self log
						error: exception description
						message: (GsProcess stackReportToLevel: 100) ] ].
		self connections removeAll ].
	self log debug: [ 'Done Closing connections' ]
]

{ #category : '*SeasideInGemStone-Compatibility' }
ZnTransactionSafeManagingMultiThreadedServer >> connections [
	| currentConnections |
	currentConnections := connections.
	(currentConnections isKindOf: TransientStackValue)
		ifTrue: [ currentConnections := currentConnections value ].
	currentConnections ifNil: [
		self _setNoStubbing.
		currentConnections := OrderedCollection new.
		connections := TransientStackValue value: currentConnections ].
	^ currentConnections
]

{ #category : '*SeasideInGemStone-Compatibility' }
ZnTransactionSafeManagingMultiThreadedServer >> initializeServerSocket [
	"Keep the listening socket in session temps so it survives the request loop
	without being persisted into the server object."

	| socket |
	self log debug: 'Initializing server socket'.
	self _setNoStubbing.
	socket := self bindingAddress
		ifNil: [ ZnNetworkingUtils serverSocketOn: self port ]
		ifNotNil: [ ZnNetworkingUtils serverSocketOn: self port interface: self bindingAddress ].
	SessionTemps current
		at: #ZnTransactionSafeManagingMultiThreadedServer_serverSocket
		put: socket.
	self log debug: 'Initialized server socket'
]

{ #category : '*SeasideInGemStone-Compatibility' }
ZnTransactionSafeManagingMultiThreadedServer >> listenLoop [
	| listeningSocket |
	self initializeServerSocket.
	listeningSocket := self serverSocket.
	[
	[
		listeningSocket isValid
			ifFalse: [ ^ self listenLoop ].
		self serveConnectionsOn: listeningSocket ]
		repeat ]
		ifCurtailed: [ self releaseServerSocket ]
]

{ #category : '*SeasideInGemStone-Compatibility' }
ZnTransactionSafeManagingMultiThreadedServer >> releaseServerSocket [
	| socket |
	socket := self serverSocket.
	socket ifNil: [ ^ self ].
	self log debug: 'Releasing server socket'.
	socket destroy.
	SessionTemps current
		removeKey: #ZnTransactionSafeManagingMultiThreadedServer_serverSocket
		ifAbsent: [ ]
]

{ #category : '*SeasideInGemStone-Compatibility' }
ZnTransactionSafeManagingMultiThreadedServer >> serveConnectionsOn: listeningSocket [
	| socket stream |
	[
	socket := listeningSocket waitForAcceptFor: self acceptWaitTimeout.
	socket ifNil: [ ^ self noteAcceptWaitTimedOut ] ]
		on: Error
		do: [ :ex |
			self logServerError: ex.
			^ self ].
	stream := self socketStreamOn: socket.
	[
	[
	[
	[ self executeRequestResponseLoopOn: stream ]
		on: Error
		do: [ :ex | self logServerError: ex ] ]
		ensure: [
			self log debug: 'Closing stream'.
			self closeSocketStream: stream ] ]
		ifCurtailed: [
			self log debug: 'Destroying socket'.
			socket destroy ] ]
		forkAt: Processor lowIOPriority
		named: self workerProcessName
]

{ #category : '*SeasideInGemStone-Compatibility' }
ZnTransactionSafeManagingMultiThreadedServer >> serverSocket [
	^ SessionTemps current
		at: #ZnTransactionSafeManagingMultiThreadedServer_serverSocket
		ifAbsent: [ nil ]
]

Extension { #name : 'ZnNewGemServer' }

{ #category : '*SeasideInGemStone-Compatibility' }
ZnNewGemServer >> basicServerOn: port [
	"Use the transient listening socket wrapper returned by the GemStone server."

	| listeningSocket znServer |
	znServer := self serverInstance.
	znServer port: port.
	znServer initializeServerSocket.
	listeningSocket := znServer serverSocket.
	listeningSocket ifNil: [ self error: 'Listening socket not initialized on port ' , port printString ].
	[
	[
		self
			gemServer: [
				listeningSocket value isValid
					ifTrue: [ znServer serveConnectionsOn: listeningSocket ] ]
			beforeUnwind: [ :ex | ex pass ] ]
		repeat ]
		ifCurtailed: [ znServer releaseServerSocket ]
]

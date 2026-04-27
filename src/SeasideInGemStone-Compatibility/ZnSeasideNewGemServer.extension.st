Extension { #name : 'ZnSeasideNewGemServer' }

{ #category : '*SeasideInGemStone-Compatibility' }
ZnSeasideNewGemServer >> basicServerOn: port [
	"Use the transient listening socket wrapper returned by the GemStone server."

	| adaptor listeningSocket znServer |
	adaptor := self serverInstance.
	znServer := adaptor server.
	znServer
		gemServer: self;
		port: port;
		gemServerOptions: self options;
		yourself.
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

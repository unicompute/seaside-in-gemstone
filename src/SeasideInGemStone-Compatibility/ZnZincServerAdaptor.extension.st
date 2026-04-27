Extension { #name : 'ZnZincServerAdaptor' }

{ #category : '*SeasideInGemStone-Compatibility' }
ZnZincServerAdaptor >> server [
	"Rebuild a stopped cached server when the image default server class changes.
	This prevents the adaptor from reusing an older incompatible server instance
	across GemStone sessions and restarts."

	| defaultServerClass |
	defaultServerClass := ZnServer defaultServerClass.
	(server isNil or: [
		server isRunning not
			and: [ server class ~~ defaultServerClass ] ])
		ifTrue: [
			server := self defaultZnServer.
			self
				configureDelegate;
				configureServerForBinaryReading ].
	^ server
]

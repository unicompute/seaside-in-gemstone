Extension { #name : 'WAGemStoneRunSeasideGems' }

{ #category : '*SeasideInGemStone-Compatibility' }
WAGemStoneRunSeasideGems class >> startGemServerOn: portInteger [
	"use this method to start adaptor in a separate gem.
	 use #startOn: if starting from development vm"

	| default serverName |
	default := self default.
	serverName := default name ifNil: [ '' ].
	serverName isEmpty ifTrue: [
		serverName := 'Seaside Gem'.
		default name: serverName ].
	GRPlatform current seasideLogServerStart: serverName port: portInteger.
	"The method not expected to return"
	self default startOn: portInteger
]

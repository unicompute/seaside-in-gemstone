Class {
	#name : 'SigExplorerSession',
	#superclass : 'WASession',
	#instVars : [
		'gateway'
	],
	#category : 'SeasideInGemStone-App',
	#package : 'SeasideInGemStone-App'
}

{ #category : 'accessing' }
SigExplorerSession >> gateway [
	gateway ifNil: [ gateway := SigGemStoneGateway new ].
	gateway sanitizeDebugSessions.
	^ gateway
]

{ #category : 'lifecycle' }
SigExplorerSession >> unregistered [
	gateway ifNotNil: [ gateway disconnect ].
	super unregistered
]

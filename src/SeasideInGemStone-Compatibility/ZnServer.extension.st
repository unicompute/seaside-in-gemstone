Extension { #name : 'ZnServer' }

{ #category : '*SeasideInGemStone-Compatibility' }
ZnServer class >> defaultServerClass [
	"Use the transaction-safe server variant in GemStone so the listening socket
	does not get persisted or disappear between request loops."

	^ ZnTransactionSafeManagingMultiThreadedServer
]

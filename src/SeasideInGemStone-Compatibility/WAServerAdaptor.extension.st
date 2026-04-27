Extension { #name : 'WAServerAdaptor class' }

{ #category : '*SeasideInGemStone-Compatibility' }
WAServerAdaptor class >> default [
	"Some GemStone images answer nil for WAAdmin serverAdaptors before the
	default server manager has finished initializing. Treat that as an empty
	registry so adaptor startup can bootstrap cleanly."

	| adaptors registeredAdaptors |
	registeredAdaptors := WAAdmin serverAdaptors ifNil: [ #() ].
	adaptors := registeredAdaptors select: [ :each | each isKindOf: self ].
	(adaptors size > 1) ifTrue: [
		self error: 'You cannot use this convenience method when more than one adaptor of the same type are registered. Use WAServerManager or a graphical interface when dealing with multiple adaptors of the same type.' ].
	^ adaptors isEmpty
		ifTrue: [ nil ]
		ifFalse: [ adaptors first ]
]

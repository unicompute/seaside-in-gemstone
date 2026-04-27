Extension { #name : 'MCRepositoryGroup' }

{ #category : '*SeasideInGemStone-Compatibility' }
MCRepositoryGroup >> repositories [
	| validRepositories |
	validRepositories := OrderedCollection new.
	(Array with: MCCacheRepository default), repositories do: [ :each |
		(each ~~ nil and: [ each isValid ])
			ifTrue: [ validRepositories add: each ] ].
	^ validRepositories
]

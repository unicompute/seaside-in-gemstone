services
tokensBasedOn: separatorString in: aString 
	"Answer an OrderedCollection of the sub-sequences
	 of the receiver that are separated by anObject."

	| result lastIdx idx lastToken |
	result := OrderedCollection new.
	lastIdx := 0.
	
	[idx := aString findString: separatorString startingAt: lastIdx + 1.
	idx > 0] 
			whileTrue: 
				[idx == (lastIdx + 1)
					ifTrue: [result addLast: String new]
					ifFalse: [result addLast: (aString copyFrom: lastIdx + 1 to: idx - 1)].
				lastIdx := idx].
	lastToken := lastIdx = aString size 
				ifTrue: [String new]
				ifFalse: [aString copyFrom: lastIdx + 1 to: aString size].
	result addLast: lastToken.
	^result

private
integerOfLength: aLength FromString: aString 
	"^an Integer or nil
	I parse an integer from aString, if I have problems I return nil.  I make sure
	the string form of the integer is exactly aLength characters long."

	"SpDate integerOfLength: 4 FromString: '2004'"

	^(aString size == aLength and: 
			[(aString asOrderedCollection select: [:aDigit | aDigit isDigit not]) 
				isEmpty]) 
		ifFalse: [nil]
		ifTrue: [aString asNumber]

services
integerFromString: aString 
	"^an Integer
We need this because of what looks like a bug in GemStone's String>>asNumber (e.g. '16rFF' -> 1.6000000000000000E+01, not 255).  Also, fromString: requires that aString not have any leading alphabetic characters.
Oh, and note the stupid fix for GemStone reseting the stream to the begining after doing an upToEnd."

"SpEnvironment integerFromString: 'ubuntu'" 

	| rawStream cleanedString |
	rawStream := ReadStream on: aString.
	cleanedString := '0'.
	[rawStream atEnd] whileFalse: 
			[rawStream peek isDigit 
				ifTrue: [cleanedString := rawStream upToEnd.
						rawStream position: aString size; next. ]
				ifFalse: [rawStream next]].
	^Integer fromString: cleanedString

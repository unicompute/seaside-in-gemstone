services
trimBlanksFrom: aString 
	"^a String
I return a copy of aString with all leading and trailing blanks removed."

	| first last |
	first := 1.
	last := aString size.
	[last > 0 and: [(aString at: last) isSeparator]] 
		whileTrue: [last := last - 1].
	^last == 0 
		ifTrue: [String new]
		ifFalse: 
			[[first < last and: [(aString at: first) isSeparator]] 
				whileTrue: [first := first + 1].
			aString copyFrom: first to: last]

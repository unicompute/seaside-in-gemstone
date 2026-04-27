services
prevIndexOf: anElement from: startIndex to: stopIndex in: aString
	"Answer the previous index of anElement within the receiver between startIndex and stopIndex
	 working backwards through the receiver.  If the receiver does not contain anElement, answer nil"

	startIndex to: stopIndex by: -1 do:
		[:i |
		(aString at: i) = anElement
			ifTrue: [^i]].
	^nil

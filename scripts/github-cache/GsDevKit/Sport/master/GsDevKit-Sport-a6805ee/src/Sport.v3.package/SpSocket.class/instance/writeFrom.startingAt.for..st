services-io
writeFrom: aByteArray startingAt: startIndex for: length 
	"^an Integer
I return the number of bytes actually written.  A GemStone socket may return nil.  This indicates that an error of some kind has occured."

	| result |
	result := self underlyingSocket 
				write: length
				from: aByteArray
				startingAt: startIndex.
	result isNil 
		ifTrue: 
			[SpSocketError raiseSignal: 'Unexpected and unknown socket error occured.'].
	^result

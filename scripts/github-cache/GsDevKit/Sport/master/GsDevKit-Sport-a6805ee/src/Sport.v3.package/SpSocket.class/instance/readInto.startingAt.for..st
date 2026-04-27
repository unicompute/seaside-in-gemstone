services-io
readInto: aByteArray startingAt: startIndex for: aNumberOfBytes 
	"^an Integer
I return the number of bytes actually read."

	| result |
	result := self underlyingSocket 
		read: aNumberOfBytes
		into: aByteArray
		startingAt: startIndex.
	result isNil 
		ifTrue: 
			[SpSocketError raiseSignal: 'Unexpected and unknown socket error occured.'].
	^result
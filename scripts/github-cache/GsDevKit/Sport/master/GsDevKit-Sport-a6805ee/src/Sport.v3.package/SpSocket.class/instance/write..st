services-io
write: sourceByteArray 
	"^an Integer
	I write the contents of the sourceByteArray to my underlying Socket.
	I return the number of bytes written."

	| result |
	result := self underlyingSocket write: sourceByteArray size
				from: sourceByteArray.
	result isNil 
		ifTrue: 
			[| errorMessageStream |
			errorMessageStream := WriteStream on: String new.
			errorMessageStream
				nextPutAll: 'Error code: ';
				nextPutAll: self underlyingSocket lastErrorCode printString;
				nextPutAll: ', Error string: ';
				nextPutAll: self underlyingSocket lastErrorString printString;
				nextPutAll: ', Error symbol: ';
				nextPutAll: self underlyingSocket lastErrorSymbol printString.
			SpSocketError raiseSignal: errorMessageStream contents].
	^result

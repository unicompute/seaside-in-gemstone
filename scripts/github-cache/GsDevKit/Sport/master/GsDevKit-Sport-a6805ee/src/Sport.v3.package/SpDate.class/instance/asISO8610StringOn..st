printing
asISO8610StringOn: aStream 
	aStream
		nextPutAll: self underlyingDate year printString;
		nextPut: $-.
	self underlyingDate monthIndex < 10 ifTrue: [aStream nextPut: $0].
	aStream
		nextPutAll: self underlyingDate monthIndex printString;
		nextPut: $-.
	self underlyingDate dayOfMonth < 10 ifTrue: [aStream nextPut: $0].
	aStream nextPutAll: self underlyingDate dayOfMonth printString.
	^self

hex
byteArrayFromHexString: aString 
	| sourceString sourceStream targetStream |
	sourceString := (aString size \\ 2) == 0 
				ifTrue: [aString]
				ifFalse: ['0' , aString].
	sourceStream := ReadStream on: sourceString.
	targetStream := WriteStream on: (ByteArray new: sourceString size / 2).
	[sourceStream atEnd] whileFalse: 
			[targetStream nextPut: (Integer fromString: '16r' , (sourceStream next: 2))].
	^targetStream contents

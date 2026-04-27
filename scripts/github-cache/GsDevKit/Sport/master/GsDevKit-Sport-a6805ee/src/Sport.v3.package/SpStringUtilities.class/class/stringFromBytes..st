services-encoding
stringFromBytes: aByteArray 
	"^a String
In GemStone ['Hello, World' asByteArray asString] returns the string 'aByteArray' !
This is the boring long way of getting a string from a ByteArray - but it does work
in GemStone."

	"HTTPString stringFromBytes: ('Hello, World' asByteArray)"

	| targetStream |
	targetStream := WriteStream on: String new.
	aByteArray do: [:aByte | targetStream nextPut: aByte asCharacter].
	^targetStream contents

services
bytesAsString: aByteArray
	"^a String
No encoding in GemStone ... yet."

	" SpStringUtilities bytesAsString: #(72 101 108 108 111 44 32 87 111 114 108 100 46) "

	| targetString |
	targetString := String new: aByteArray size.
	1 to: aByteArray size
		do: [:index | targetString at: index put: (Character withValue: (aByteArray at: index))].
	^targetString

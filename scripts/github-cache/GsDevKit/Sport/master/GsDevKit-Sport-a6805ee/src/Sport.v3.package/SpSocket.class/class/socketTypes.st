defined symbols
socketTypes
	"^an IdentityDictionary
	I return the dictionary mapping each defined socket type symbol to it's numeric
	value.  See socket.h and look for the #define SOCK_xxx lines.
	If you modify this method, evaluate the following:
		'SpSocket resetAllDefinedValues' "

	socketTypes isNil 
		ifTrue: 
			[socketTypes := (IdentityDictionary new)
						at: #SOCK_STREAM put: 1;
						yourself].
	^socketTypes

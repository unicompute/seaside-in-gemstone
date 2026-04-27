defined symbols
socketOptions
	"^an IdentityDictionary
	I return the dictionary mapping each defined socket option symbol to it's numeric
	value.  See socket.h and look for the #define SO_xxx lines.
	If you modify this method, evaluate the following:
		'SpSocket resetAllDefinedValues' "

	socketOptions isNil 
		ifTrue: 
			[socketOptions := (IdentityDictionary new)
						at: #SO_REUSEADDR put: 2;
						yourself].
	^socketOptions

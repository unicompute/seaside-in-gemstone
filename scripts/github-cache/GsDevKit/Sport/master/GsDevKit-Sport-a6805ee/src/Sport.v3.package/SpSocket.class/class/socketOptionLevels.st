defined symbols
socketOptionLevels
	"^an IdentityDictionary
	I return the dictionary mapping each defined socket option level symbol to it's numeric
	value.  See socket.h and look for the #define SOL_xxx lines.
	If you modify this method, evaluate the following:
		'SpSocket resetAllDefinedValues' "

	socketOptionLevels isNil 
		ifTrue: 
			[socketOptionLevels := (IdentityDictionary new)
						at: #SOL_SOCKET put: 1;
						yourself].
	^socketOptionLevels

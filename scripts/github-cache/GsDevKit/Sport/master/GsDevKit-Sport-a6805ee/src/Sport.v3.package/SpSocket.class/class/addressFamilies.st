defined symbols
addressFamilies
	"^an IdentityDictionary
	I return the dictionary mapping each defined address family symbol to it's numeric
	value.  See socket.h and look for the #def AF_xxx lines.
	If you modify this method, evaluate the following:
		'SpSocket resetAllDefinedValues' "

	addressFamilies isNil 
		ifTrue: 
			[addressFamilies := (IdentityDictionary new)
						at: #AF_UNIX put: 1;
						at: #AF_LOCAL put: 1;
						at: #AF_INET put: 2;
						yourself].
	^addressFamilies

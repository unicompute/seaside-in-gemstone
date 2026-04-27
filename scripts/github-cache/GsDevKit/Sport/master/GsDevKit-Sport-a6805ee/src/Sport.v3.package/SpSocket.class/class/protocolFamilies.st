defined symbols
protocolFamilies
	"^an IdentityDictionary
	I return the dictionary mapping each defined protocol family symbol to it's numeric
	value.  See socket.h and look for the #def PF_xxx lines.
	If you modify this method, evaluate the following:
		'SpSocket resetAllDefinedValues' "

	protocolFamilies isNil 
		ifTrue: 
			[protocolFamilies := (IdentityDictionary new)
						at: #PF_UNIX put: (self addressFamilies at: #AF_UNIX);
						at: #PF_LOCAL put: (self addressFamilies at: #AF_LOCAL);
						at: #PF_INET put: (self addressFamilies at: #AF_INET);
						yourself].
	^protocolFamilies

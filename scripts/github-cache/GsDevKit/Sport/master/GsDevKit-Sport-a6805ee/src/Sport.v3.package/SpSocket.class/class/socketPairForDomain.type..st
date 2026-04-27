instance creation
socketPairForDomain: aCommunicationsDomain type: aSocketType 
	"^an SpSocket
	see: man socketpair
	Default the protocol to zero - this is the default  in the Spec anyway. "

	^self 
		socketPairForDomain: aCommunicationsDomain
		type: aSocketType
		protocol: 0

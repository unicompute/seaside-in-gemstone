instance creation
forDomain: aCommunicationsDomain type: aSocketType 
	"^an SpSocket
	Default the protocol to zero - this is the default  in the Spec anyway.  See man socket.."

	^self 
		forDomain: aCommunicationsDomain
		type: aSocketType
		protocol: 0

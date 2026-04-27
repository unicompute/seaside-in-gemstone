initialize-release
onNativeSocket: aSocket forDomain: aCommunicationDomain type: aSocketType protocol: aProtocolNumber 
	"^self
	I initialize myself as a socket defined by the communications domain, type and protocol.  This
	follows the equivalent of the using the socket()  or socketpair() function."

	communicationDomain := aCommunicationDomain.
	socketType := aSocketType.
	protocolNumber := aProtocolNumber.
	underlyingSocket := aSocket.
	^self

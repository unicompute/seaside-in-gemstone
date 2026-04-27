instance creation
forDomain: aDomainSymbol type: aSocketTypeSymbol protocol: aProtocolNumber 
	"^an SpSocket
	Equivalent of int socket(int domain, int type, int protocol);  see man socket.
	I return a new instance of myself that represents a socket configured for the
	specified domain type and protocol .
	Note in GS we can't specify any of the regular socket stuff - it's TCP Stream only!"

	| newNativeSocket |
	newNativeSocket := GsSocket new.
	^self new 
		onNativeSocket: newNativeSocket
		forDomain: aDomainSymbol
		type: aSocketTypeSymbol
		protocol: aProtocolNumber

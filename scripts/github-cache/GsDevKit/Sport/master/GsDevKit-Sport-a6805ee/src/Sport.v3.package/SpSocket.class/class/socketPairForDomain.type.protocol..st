instance creation
socketPairForDomain: aDomainSymbol type: aTypeSymbol protocol: aProtocolNumber 
	"^an SpSocket
	See: man socketpair
	Equivalent of int socketpair(int d, int type, int protocol, int sv[2]); 
	I return and array containing two new instances of myself each representing
	one end of a connection.
	No direct way to do this in GS - I'll look at it when I need it."

	"SocketAccessor openPair collect: 
			[:newNativeSocket | 
			self new 
				onNativeSocket: newNativeSocket
				forDomain: aDomainSymbol
				type: aTypeSymbol
				protocol: aProtocolNumber]"
	^1 halt: 'Doh! - not supported in GS'

services-accessing
getPeerName
	"^an SpSocketAddress
	see man getpeername.
	I return the socket address of the other/remote/peer end of the socket I represent."

	^SpIPAddress host: self underlyingSocket peerAddress port: self underlyingSocket peerPort

services
connectToServerOnHost: hostName port: portNumber 
	"^an SpSocket 
	I return a new instance of myself which represents a socket connecter to a server listening on portNumber at hostName."

	| newSocket |
	newSocket := self newTCPSocket.
	newSocket connectTo: (SpIPAddress hostName: hostName port: portNumber).
	^newSocket

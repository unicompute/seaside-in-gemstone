services
newTCPSocket
	"^an SpSocket
	I create and return a new socket configured to be of a streaming type handle the 
	IPv4 peotocol family (default protocol).  This is a tcp_socket (see man 7 ip)."

	^self forDomain: #PF_INET type: #SOCK_STREAM

services-status
bindSocketAddress: aSocketAddress 
	"^self
	Equivalent of:  bind(int  sockfd, struct sockaddr *my_addr, socklen_t addrlen);
	see man bind.
	Bind the socket to aSocketAddress."

	self underlyingSocket bindTo: aSocketAddress portNumber toAddress: aSocketAddress hostAddressString.
	^self

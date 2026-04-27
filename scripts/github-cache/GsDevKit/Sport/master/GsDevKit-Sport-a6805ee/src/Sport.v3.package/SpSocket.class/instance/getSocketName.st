services-accessing
getSocketName
	"^an SpSocketAddress
	see: man getsockname
	I return my local socket address which may be any subclass of 
	SpSocketAddress."

	^SpIPAddress host: self underlyingSocket address port: self underlyingSocket port

services-status
connectTo: aSocketAddress
  "^self
	I instruct my underlying socket to connect to aSocketAddress."

  (self underlyingSocket
    connectTo: aSocketAddress portNumber
    on: aSocketAddress hostAddressString)
    ifFalse: [ 
      SpSocketError
        raiseSignal:
          'Socket connect error: ' , self underlyingSocket lastErrorString asString ].
  ^ self
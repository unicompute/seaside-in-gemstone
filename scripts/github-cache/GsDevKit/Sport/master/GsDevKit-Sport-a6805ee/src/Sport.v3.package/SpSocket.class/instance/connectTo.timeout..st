services-status
connectTo: aSocketAddress timeout: timeoutSeconds
  "^self
	I instruct my underlying socket to connect to aSocketAddress.
   timeoutSeconds is a SmallInteger specifying maximum time to wait for the
   connection to complete, or -1 to wait indefinitely."

  (self underlyingSocket
    connectTo: aSocketAddress portNumber
    on: aSocketAddress hostAddressString
    timeoutMs: timeoutSeconds * 1000)
    ifFalse: [ 
      SpSocketError
        raiseSignal:
          'Socket connect error: ' , self underlyingSocket lastErrorString asString ].
  ^ self
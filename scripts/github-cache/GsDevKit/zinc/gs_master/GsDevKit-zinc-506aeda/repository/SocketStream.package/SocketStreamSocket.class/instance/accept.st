as yet unclassified
accept
  "^an SpSocket
	I accept the next connection made to the server socket I represent.  I return a new
	instance of SpSocket which represents the socket over which information can be
	exchanged.
	NOTE: this call will block waiting for an inbound connection"

  | gsSocket |
  gsSocket := self underlyingSocket accept.
  gsSocket
    ifNil: [ 
      NetworkError
        signal:
          'accept error: ' , self underlyingSocket lastErrorString asString ].
  ^ SocketStreamSocket onNativeclientSocket: gsSocket for: self
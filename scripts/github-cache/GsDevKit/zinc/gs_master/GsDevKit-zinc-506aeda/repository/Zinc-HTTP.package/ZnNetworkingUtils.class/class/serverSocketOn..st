as yet unclassified
serverSocketOn: port
  | socket |
  socket := SocketStreamSocket newTCPSocket.
  self setServerSocketOptions: socket.
  (socket listenOn: port backlogSize: self listenBacklogSize)
    ifNil: [ 
      self
        error:
          'Error listening on socket: ' , socket underlyingSocket lastErrorString ].
  socket isValid
    ifFalse: [ self error: 'Cannot create socket on port ' , port printString ].
  ^ socket
request handling
serveConnectionsOn: listeningSocketTransientStackValue
  "We wait up to acceptWaitTimeout seconds for an incoming connection.
	If we get one we wrap it in a SocketStream and #executeRequestResponseLoopOn: on it"

  | stream socket |
  socket := TransientStackValue
    value:
      (listeningSocketTransientStackValue value
        waitForAcceptFor: self acceptWaitTimeout).
  socket value ifNil: [ ^ self noteAcceptWaitTimedOut ].
  stream := TransientStackValue value: (self socketStreamOn: socket value).
  [ 
  self log debug: 'Executing request/response loop'.
  ZnCurrentServer
    value: self
    during: [ self executeOneRequestResponseOn: stream ] ]
    forkAt: Processor lowIOPriority
    named: self workerProcessName
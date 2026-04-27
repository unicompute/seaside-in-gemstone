request handling
serveConnectionsOn: listeningSocketTransientStackValue
  "We wait up to acceptWaitTimeout seconds for an incoming connection.
	If we get one we wrap it in a SocketStream and #executeRequestResponseLoopOn: on it"

  | stream socket |
  [ 
  socket := TransientStackValue
    value:
      (listeningSocketTransientStackValue value
        waitForAcceptFor: self acceptWaitTimeout).
  socket value ifNil: [ ^ self noteAcceptWaitTimedOut ] ]
    on: Error
    do: [ :ex | 
      self logServerError: ex.
      ^ self ].
  stream := TransientStackValue value: (self socketStreamOn: socket value).
  [ 
  [ 
  [ 
  [ self executeRequestResponseLoopOn: stream ]
    on: Error
    do: [ :ex | self logServerError: ex ] ]
    ensure: [ 
      self log debug: 'Closing stream'.
      self closeSocketStream: stream value ] ]
    ifCurtailed: [ 
      self log debug: 'Destroying socket'.
      socket value destroy ] ]
    forkAt: Processor lowIOPriority
    named: self workerProcessName
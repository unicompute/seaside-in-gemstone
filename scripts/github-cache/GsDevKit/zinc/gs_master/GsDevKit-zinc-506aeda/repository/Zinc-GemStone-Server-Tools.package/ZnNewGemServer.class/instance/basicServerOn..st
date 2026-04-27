service instance-server
basicServerOn: port
  "forked by caller"

  | znServer |
  znServer := self serverInstance.
  znServer port: port.
  znServer initializeServerSocket.
  [ 
  [ 
  self
    gemServer: [ 
      znServer serverSocket isValid
        ifTrue: [ znServer serveConnectionsOn: znServer serverSocket ] ]
    beforeUnwind: [ :ex | ex pass ] ]
    repeat ]
    ifCurtailed: [ znServer releaseServerSocket ]
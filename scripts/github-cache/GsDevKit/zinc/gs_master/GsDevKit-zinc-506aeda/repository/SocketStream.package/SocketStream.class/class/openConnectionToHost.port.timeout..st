as yet unclassified
openConnectionToHost: host port: portNumber timeout: timeoutSeconds
  | socket |
  socket := SocketStreamSocket newTCPSocket.
  socket connectTo: host port: portNumber timeout: timeoutSeconds.
  ^ (self on: socket)
    timeout: timeoutSeconds;
    yourself
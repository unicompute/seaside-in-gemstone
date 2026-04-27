private
releaseServerSocket
  "Release our server socket"

  serverSocket value ifNil: [ ^ self ].
  self log debug: 'Releasing server socket'.
  serverSocket value destroy.
  serverSocket := nil
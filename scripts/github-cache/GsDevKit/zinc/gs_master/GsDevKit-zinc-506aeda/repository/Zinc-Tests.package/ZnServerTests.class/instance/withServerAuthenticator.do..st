private
withServerAuthenticator: authenticator do: block
  | server |
  server := super withServerDo: block.
  server authenticator: authenticator.
  [ 
  server start.
  self assert: server isRunning & server isListening.
  block cull: server ]
    ensure: [ server stop ]
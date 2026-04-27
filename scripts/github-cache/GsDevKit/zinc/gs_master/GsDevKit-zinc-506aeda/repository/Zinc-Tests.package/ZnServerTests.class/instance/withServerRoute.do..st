private
withServerRoute: route do: block
  | server |
  server := super withServerDo: block.
  server route: route.
  [ 
  server start.
  self assert: server isRunning & server isListening.
  block cull: server ]
    ensure: [ server stop ]
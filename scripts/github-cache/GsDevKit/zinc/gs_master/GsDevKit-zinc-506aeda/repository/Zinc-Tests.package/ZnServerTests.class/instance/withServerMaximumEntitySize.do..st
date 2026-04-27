private
withServerMaximumEntitySize: maximumEntitySize do: block
  | server |
  server := super withServerDo: block.
  server maximumEntitySize: maximumEntitySize.
  [ 
  server start.
  self assert: server isRunning & server isListening.
  block cull: server ]
    ensure: [ server stop ]
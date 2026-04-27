private
withServerReader: reader do: block
  | server |
  server := super withServerDo: block.
  server reader: reader.
  [ 
  server start.
  self assert: server isRunning & server isListening.
  block cull: server ]
    ensure: [ server stop ]
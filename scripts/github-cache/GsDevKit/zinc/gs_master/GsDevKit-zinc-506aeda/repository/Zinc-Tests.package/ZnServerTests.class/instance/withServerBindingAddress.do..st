private
withServerBindingAddress: bindingAddress do: block
  | server |
  server := super withServerDo: block.
  server bindingAddress: bindingAddress.
  [ 
  server start.
  self assert: server isRunning & server isListening.
  block cull: server ]
    ensure: [ server stop ]
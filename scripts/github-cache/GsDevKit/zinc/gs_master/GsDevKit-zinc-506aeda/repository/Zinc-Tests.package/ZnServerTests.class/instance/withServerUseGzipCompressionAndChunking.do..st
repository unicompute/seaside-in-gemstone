private
withServerUseGzipCompressionAndChunking: useGzipCompressionAndChunking do: block
  | server |
  server := super withServerDo: block.
  server useGzipCompressionAndChunking: useGzipCompressionAndChunking.
  [ 
  server start.
  self assert: server isRunning & server isListening.
  block cull: server ]
    ensure: [ server stop ]
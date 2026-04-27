private
withServerUseGzipCompressionAndChunking: useGzipCompressionAndChunking do: block
  self
    withGemServerUseGzipCompressionAndChunking: useGzipCompressionAndChunking
    do: block
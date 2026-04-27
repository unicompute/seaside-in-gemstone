private
withGemServerUseGzipCompressionAndChunking: useGzipCompressionAndChunking do: block
  | gemServer |
  gemServer := super withGemServerDo: block.
  gemServer useGzipCompressionAndChunking: useGzipCompressionAndChunking.
  self runGemServer: gemServer during: block
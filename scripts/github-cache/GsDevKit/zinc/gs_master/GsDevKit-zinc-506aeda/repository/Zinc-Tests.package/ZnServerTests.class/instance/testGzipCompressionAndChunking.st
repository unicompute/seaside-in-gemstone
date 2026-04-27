testing
testGzipCompressionAndChunking
  self
    withServerUseGzipCompressionAndChunking: true
    do: [ :server | 
      | client |
      (client := ZnClient new)
        url: server localUrl;
        addPathSegment: 'dw-bench';
        setAcceptEncodingGzip;
        get.
      self assert: client isSuccess.
      self assert: client response hasContentEncoding.
      self
        assert: (client response headers at: 'Content-Encoding')
        equals: 'gzip'.
      self assert: client response hasTransferEncoding.
      self
        assert: (client response headers at: 'Transfer-Encoding')
        equals: 'chunked' ]
testing
testEchoLocalInterface
  self
    withServerBindingAddress: (GsSocket getHostAddressByName: 'localhost')
    do: [ :server | 
      | response |
      response := ZnEasy
        get:
          (server localUrl
            addPathSegments: #('echo' 'foo');
            yourself).
      self assert: response contentType = ZnMimeType textPlain.
      self assert: response statusLine code = 200.
      self assert: (response entity contents includesSubstring: 'Zinc').
      self assert: (response entity contents includesSubstring: 'foo') ]
testing
testEcho
  self
    withServerDo: [ :server | 
      | response |
      response := ZnEasy
        get:
          (server localUrl
            addPathSegments: #('echo' 'foo');
            yourself).
      self assert: response contentType = ZnMimeType textPlain.
      self assert: response statusLine code = 200.
      self assert: (response entity contents includesSubstring: 'Zinc').
      self assert: (response entity contents includesSubstring: 'foo').
      (server isKindOf: ZnServer)
        ifTrue: [ self assert: (response entity contents includesSubstring: server printString) ]
        ifFalse: [ 
          "a little more difficult to get server printString for a GemServer"
          self
            assert:
              (response entity contents
                includesSubstring:
                  server serverClass defaultServerClass name asString) ] ]
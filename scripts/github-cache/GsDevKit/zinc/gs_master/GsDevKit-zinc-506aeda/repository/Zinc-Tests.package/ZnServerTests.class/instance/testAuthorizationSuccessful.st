testing
testAuthorizationSuccessful
  self
    withServerAuthenticator:
      (ZnBasicAuthenticator username: 'foo' password: 'secret')
    do: [ :server | 
      | response |
      response := ZnEasy
        get:
          (server localUrl
            addPathSegments: #('echo' 'foo');
            yourself)
        username: 'foo'
        password: 'secret'.
      self assert: response headers contentType = ZnMimeType textPlain.
      self assert: response statusLine code = 200.
      self assert: (response entity string includesSubstring: 'Zinc').
      self assert: (response entity string includesSubstring: 'foo') ]
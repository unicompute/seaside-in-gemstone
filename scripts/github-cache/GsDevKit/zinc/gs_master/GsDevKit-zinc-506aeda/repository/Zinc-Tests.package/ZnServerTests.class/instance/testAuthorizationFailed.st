testing
testAuthorizationFailed
  self
    withServerAuthenticator:
      (ZnBasicAuthenticator username: 'foo' password: 'secret')
    do: [ :server | 
      | response |
      response := ZnEasy
        get:
          (server localUrl
            addPathSegment: 'echo';
            yourself).
      self assert: response headers contentType = ZnMimeType textPlain.
      self assert: response statusLine code = 401.
      self
        assert:
          ((response headers at: 'WWW-Authenticate') includesSubstring: 'Basic').
      self
        assert:
          ((response headers at: 'WWW-Authenticate') includesSubstring: 'Zinc') ]
testing
testUsernamePasswordInUserInfo
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  self
    withServerDo: [ :server | 
      | url client |
      server
        authenticator: (ZnBasicAuthenticator username: 'foo' password: 'secret').
      url := server localUrl.
      url
        username: 'foo';
        password: 'secret';
        addPathSegment: 'echo'.
      (client := ZnClient new) get: url.
      self assert: client isSuccess.
      self assert: (client contents includesSubstring: 'Zinc').
      client close ]
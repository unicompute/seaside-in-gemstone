testing
testPostTwice
  | client |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  self
    withServerDo: [ :server | 
      (client := ZnClient new)
        url: server localUrl;
        addPath: 'echo';
        contents: 'Foo bar!';
        post.
      self assert: client isSuccess.
      self assert: (client contents includesSubstring: 'Foo bar!').
      client
        contents: 'Another one ?';
        post.
      self assert: client isSuccess.
      self assert: (client contents includesSubstring: 'Another one ?').
      client close ]
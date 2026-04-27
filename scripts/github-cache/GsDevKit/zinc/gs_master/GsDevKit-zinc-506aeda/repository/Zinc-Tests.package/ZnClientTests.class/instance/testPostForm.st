testing
testPostForm
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
        formAt: 'username' put: 'john';
        formAdd: 'password' -> 'secret';
        post.
      self assert: client isSuccess.
      self assert: (client contents includesSubstring: 'john').
      self assert: (client contents includesSubstring: 'secret') ]
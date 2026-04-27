testing
testHeadSmallHTML
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
        head.
      self assert: client isSuccess.
      self assert: client response contentLength > 0.
      self assert: client response hasEntity not.
      client close ]
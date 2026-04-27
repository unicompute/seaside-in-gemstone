testing
testTimeout
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  self
    withServerDo: [ :server | 
      self
        should: [ 
          ZnClient new
            timeout: 1;
            url: server localUrl;
            addPath: 'echo';
            queryAt: 'delay' put: '2';
            get ]
        raise: ConnectionTimedOut ]
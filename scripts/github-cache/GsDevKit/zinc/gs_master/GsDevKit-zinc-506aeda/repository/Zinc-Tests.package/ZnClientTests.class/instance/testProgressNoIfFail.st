testing
testProgressNoIfFail
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  self
    should: [ 
      ZnClient new
        beOneShot;
        signalProgress: true;
        ifFail: [ self fail ];
        get: 'http://zn.stfx.eu/zn/small.html' ]
    raise: HTTPProgress
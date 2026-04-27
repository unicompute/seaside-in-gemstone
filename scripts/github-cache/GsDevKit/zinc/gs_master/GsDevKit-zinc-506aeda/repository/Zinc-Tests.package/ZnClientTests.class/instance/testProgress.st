testing
testProgress
  "UIManager default informUserDuring: [ :bar |
		[ ^ ZnClient new
				signalProgress: true;
				get: 'http://zn.stfx.eu/echo?delay=2' ]
			on: HTTPProgress 
			do: [ :progress | bar value: progress printString. progress resume ] ]"

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
        get: 'http://zn.stfx.eu/zn/small.html' ]
    raise: HTTPProgress
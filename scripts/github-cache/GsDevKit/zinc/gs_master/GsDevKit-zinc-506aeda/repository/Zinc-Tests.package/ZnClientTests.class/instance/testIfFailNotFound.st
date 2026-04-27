testing
testIfFailNotFound
  | client |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  (client := ZnClient new)
    beOneShot;
    url: 'http://stfx.eu/non-existing';
    ifFail: [ :exception | ^ self assert: (exception isKindOf: ZnHttpUnsuccessful) ];
    get.
  self assert: client isSuccess not.
  client
    enforceHttpSuccess: true;
    get.
  self fail
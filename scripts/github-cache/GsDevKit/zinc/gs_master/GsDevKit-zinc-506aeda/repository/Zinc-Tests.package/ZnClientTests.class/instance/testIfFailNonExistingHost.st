testing
testIfFailNonExistingHost
  | client |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  (client := ZnClient new)
    beOneShot;
    url: 'http://unknown-stfx.eu';
    ifFail: [ :exception | ^ self ];
    get.
  self fail
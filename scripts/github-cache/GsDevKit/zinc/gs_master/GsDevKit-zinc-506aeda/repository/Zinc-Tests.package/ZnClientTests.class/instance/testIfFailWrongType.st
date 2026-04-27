testing
testIfFailWrongType
  | client |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  (client := ZnClient new)
    beOneShot;
    accept: ZnMimeType imagePng;
    enforceAcceptContentType: true;
    url: 'http://zn.stfx.eu/zn/small.html';
    ifFail: [ :exception | ^ self assert: (exception isKindOf: ZnUnexpectedContentType) ];
    get.
  self fail
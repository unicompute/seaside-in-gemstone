testing
testGetSmallHTMLUrlConstruction
  | client |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  (client := ZnClient new)
    http;
    host: 'zn.stfx.eu';
    path: '/zn/small.html';
    get.
  self assert: client isSuccess.
  self assert: client response contentType = ZnMimeType textHtml.
  self assert: (client contents includesSubstring: 'Small').
  client close
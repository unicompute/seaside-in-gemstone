testing
testQueryBing
  | client |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  (client := ZnClient new)
    http;
    host: 'www.bing.com';
    addPath: 'search';
    queryAt: 'q' put: 'Pharo Smalltalk';
    get.
  self assert: client isSuccess.
  self assert: (client response contentType matches: ZnMimeType textHtml).
  self assert: (client contents includesSubstring: 'pharo.org').
  client close
testing
testIfModifiedSinceNotModified
  | client request response |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  (client := ZnClient new) host: 'stfx.eu'.
  [ 
  response := client
    url: '/small.html';
    setIfModifiedSince: (Date year: 2012 month: 9 day: 1);
    get;
    response.
  self assert: response isNotModified.
  self assert: response hasEntity not ]
    ensure: [ client close ]
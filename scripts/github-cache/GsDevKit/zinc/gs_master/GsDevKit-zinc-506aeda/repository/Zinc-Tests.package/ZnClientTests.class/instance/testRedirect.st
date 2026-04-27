testing
testRedirect
  | client response target |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  target := 'http://zn.stfx.eu'.
  client := ZnClient new url: target.
  client get.
  self assert: client isSuccess.
  client
    close;
    maxNumberOfRedirects: 0;
    url: target.
  self should: [ client get ] raise: ZnTooManyRedirects.
  client close.
  response := [ 
  ZnClient new
    beOneShot;
    maxNumberOfRedirects: 0;
    get: target;
    response ]
    on: ZnTooManyRedirects
    do: [ :exception | exception resume ].
  self assert: response isRedirect
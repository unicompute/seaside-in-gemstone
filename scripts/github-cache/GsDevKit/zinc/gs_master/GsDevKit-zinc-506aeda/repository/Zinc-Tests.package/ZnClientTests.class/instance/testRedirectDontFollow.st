testing
testRedirectDontFollow
  | client target |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  target := 'http://zn.stfx.eu'.
  (client := ZnClient new)
    dontFollowRedirects;
    get: target.
  self assert: client response isRedirect.
  client
    enforceHttpSuccess: true;
    get: target.
  self assert: client response isRedirect.
  client close
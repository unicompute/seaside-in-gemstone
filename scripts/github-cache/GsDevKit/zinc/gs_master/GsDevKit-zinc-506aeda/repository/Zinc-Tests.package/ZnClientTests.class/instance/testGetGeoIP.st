testing
testGetGeoIP
  | result client |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.3.1' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test"
      ^ self ].
  result := (client := ZnClient new)
    systemPolicy;
    url: 'http://easy.t3-platform.net/rest/geo-ip';
    queryAt: 'address' put: '81.83.7.35';
    accept: ZnMimeType applicationJson;
    contentReader: [ :entity | STON fromString: entity contents ];
    ifFail: [ :ex | 
          Transcript
            cr;
            show: 'testGetGeoIP FAIL: ' , ex description.
          ^ self fail ];
    get.
  self assert: result isDictionary.
  self assert: (result at: 'country') = 'BE'.
  client close
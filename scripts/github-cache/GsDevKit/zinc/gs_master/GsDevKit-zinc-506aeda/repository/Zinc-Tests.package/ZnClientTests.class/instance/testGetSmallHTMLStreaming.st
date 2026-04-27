testing
testGetSmallHTMLStreaming
  | client result contents |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  result := (client := ZnClient new)
    url: 'http://zn.stfx.eu/zn/small.html';
    streaming: true;
    get.
  self assert: client isSuccess.
  self assert: client response contentType = ZnMimeType textHtml.
  self assert: result isStream.
  self assert: client entity stream = result.
  contents := ZnUTF8Encoder new decodeBytes: result upToEnd.
  self assert: (contents includesSubstring: 'Small').
  client close
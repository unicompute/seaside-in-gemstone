testing
testSlashdotGzipChunked
  [ 
  | request stream response contents |
  (request := ZnRequest get: 'http://slashdot.org')
    setConnectionClose;
    setAcceptEncodingGzip.
  stream := ZnNetworkingUtils socketStreamToUrl: request url.
  response := [ 
  request writeOn: stream.
  stream flush.
  ZnResponse readFrom: stream ]
    ensure: [ stream close ].
  response isRedirect
    ifTrue: [ ^ self ].
  self assert: response code = 200.
  self assert: ((response headers at: 'Content-Type') beginsWith: 'text/html').
  self
    assert:
      (response headers at: 'Content-Encoding' ifAbsent: [ 'gzip' ]) = 'gzip'.
  self
    assert:
      (response headers at: 'Transfer-Encoding' ifAbsent: [ 'chunked' ]) = 'chunked'.
  contents := response entity contents.
  self
    assert:
      ((contents includesSubstring: 'Slashdot')
        or: [ contents includesSubstring: 'refresh' ]) ]
    on: Error
    do: [ :ex | 
      Transcript
        cr;
        show:
            self class name asString , '>>testSlashdotGzipChunked: ' , ex description;
        show: (GsProcess stackReportToLevel: 100) ]
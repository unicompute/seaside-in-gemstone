testing
testError
  Transcript
    cr;
    show: 'testError: ' , self class name printString.
  self
    withServerDo: [ :server | 
      | url response |
      self deny: server debugMode.
      url := server localUrl
        addPathSegment: #'error';
        queryAt: #'message' put: 'Test Error';
        yourself.
      response := ZnEasy get: url.
      Transcript
        cr;
        show:
            'testError: ' , response isSuccess printString , ' ' , response code printString
                , ' ' , response contentType printString , ' '
                , ZnMimeType textPlain printString , ' '
                , (response contentType = ZnMimeType textPlain) printString
                , ' '
                ,
                  (response entity contents includesSubstring: 'Test Error') printString.
      Transcript
        cr;
        show: 'testError: [0]'.
      self deny: response isSuccess.
      Transcript
        cr;
        show: 'testError: [1]'.
      self assert: response code equals: 500.
      Transcript
        cr;
        show: 'testError: [2]'.
      self assert: response contentType = ZnMimeType textPlain.
      Transcript
        cr;
        show: 'testError: [3]'.
      self assert: (response entity contents includesSubstring: 'Test Error').
      Transcript
        cr;
        show: 'testError: [4]' ]
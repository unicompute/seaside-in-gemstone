testing
testTransaction
  "UserGlobals at: #'ZnServerBasedTestServer_TestDictionary'"

  [ 
  | globalName fieldName fieldValue |
  System abortTransaction.
  globalName := self gemServerName , '_TestDictionary'.
  UserGlobals at: globalName asSymbol put: Dictionary new.
  System commitTransaction.
  fieldName := 'testField'.
  fieldValue := 1000 atRandom asString.
  self
    withServerDo: [ :server | 
      | response |
      response := ZnEasy
        get:
          (server localUrl
            addPathSegments: #('transaction');
            queryAt: #'globalName' put: globalName;
            queryAt: #'fieldName' put: fieldName;
            queryAt: #'fieldValue' put: fieldValue;
            yourself).
      self assert: response contentType = ZnMimeType textPlain.
      self assert: response statusLine code = 200.
      System abortTransaction.
      self
        assert:
          ((UserGlobals at: globalName asSymbol) at: fieldName) = fieldValue ] ]
    on: Error
    do: [ :ex | 
      Transcript
        cr;
        show: self class name asString , '>>testTransaction: ' , ex description;
        show: (GsProcess stackReportToLevel: 100) ]
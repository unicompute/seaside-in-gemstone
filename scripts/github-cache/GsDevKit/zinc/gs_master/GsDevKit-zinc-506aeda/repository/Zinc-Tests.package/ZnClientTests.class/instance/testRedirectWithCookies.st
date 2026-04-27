testing
testRedirectWithCookies
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  self
    withServerDo: [ :server | 
      | client cookie |
      server
        onRequestRespond: [ :request | 
          request uri firstPathSegment = 'one'
            ifTrue: [ 
              (ZnResponse redirect: 'two')
                addCookie: (ZnCookie name: 'session' value: '123456');
                yourself ]
            ifFalse: [ 
              cookie := request cookies
                detect: [ :each | each name = 'session' ]
                ifNone: [ nil ].
              (request uri firstPathSegment = 'two'
                and: [ cookie notNil and: [ cookie value = '123456' ] ])
                ifTrue: [ ZnResponse ok: (ZnEntity text: 'OK!') ]
                ifFalse: [ ZnResponse badRequest: request ] ] ].
      (client := ZnClient new)
        url: server localUrl;
        addPath: 'one';
        post.
      self assert: client isSuccess.
      self assert: client contents = 'OK!'.
      client close ]
testing
testGetAfterPost
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  self
    withServerDo: [ :server | 
      | client |
      server
        onRequestRespond: [ :request | 
          request uri firstPathSegment = 'one'
            ifTrue: [ 
              (request method = #'POST' and: [ request hasEntity ])
                ifTrue: [ ZnResponse ok: (ZnEntity text: 'OK for one') ]
                ifFalse: [ ZnResponse badRequest: request ] ]
            ifFalse: [ 
              request uri firstPathSegment = 'two'
                ifTrue: [ 
                  (request method = #'GET' and: [ request hasEntity not ])
                    ifTrue: [ ZnResponse ok: (ZnEntity text: 'OK for two') ]
                    ifFalse: [ ZnResponse badRequest: request ] ]
                ifFalse: [ ZnResponse notFound: request uri ] ] ].
      (client := ZnClient new)
        url: server localUrl;
        url: 'one';
        entity: (ZnEntity text: 'One two three');
        post.
      self assert: client isSuccess.
      self assert: client contents = 'OK for one'.
      client
        url: 'two';
        get.
      self assert: client isSuccess.
      self assert: client contents = 'OK for two'.
      client close ]
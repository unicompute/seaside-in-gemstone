request handling
executeOneRequestResponseOn: streamTransientStackValue
  "forked by caller"

  "Execute one HTTP request / response cycle on stream in 3 steps
	#readRequest: #handleRequest: and #writeResponse:on:
	Return true when the outer loop we are in should stop."

  self
    serve: [ 
      | request response |
      request := self
        serve: [ 
          self
            serve: [ self readRequest: streamTransientStackValue ]
            on: self readRequestBadExceptionSet
            do: [ :ex | ^ self writeResponseBad: ex on: streamTransientStackValue value ] ]
        on: self readRequestTerminationExceptionSet
        do: [ :ex | ^ self ].
      response := self handleRequest: request.
      self augmentResponse: response forRequest: request.
      self
        serve: [ self writeResponse: response on: streamTransientStackValue ]
        on: self writeResponseTerminationExceptionSet
        do: [ :ex | ex return: nil ].
      response useConnection: streamTransientStackValue value.
      (request wantsConnectionClose or: [ response wantsConnectionClose ])
        ifTrue: [ ^ self ] ]
    ensure: [ self closeSocketStream: streamTransientStackValue value ]
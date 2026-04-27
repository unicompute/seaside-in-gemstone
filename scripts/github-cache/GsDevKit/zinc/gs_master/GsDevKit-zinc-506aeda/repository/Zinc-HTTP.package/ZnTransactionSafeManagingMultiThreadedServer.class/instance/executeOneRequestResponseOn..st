request handling
executeOneRequestResponseOn: streamTransientStackValue
  "Execute one HTTP request / response cycle on stream in 3 steps
	#readRequest: #handleRequest: and #writeResponse:on:
	Return true when the outer loop we are in should stop."

  | request response |
  (request := self readRequestSafely: streamTransientStackValue)
    ifNil: [ ^ true ]
    ifNotNil: [ 
      [ 
      response := self handleRequest: request.
      self augmentResponse: response forRequest: request.
      self writeResponseSafely: response on: streamTransientStackValue.
      response useConnection: streamTransientStackValue value ]
        on: Error
        do: [ :exception | 
          self log
            error: exception description
            message: (GsProcess stackReportToLevel: 100).
          exception pass ] ].
  ^ request wantsConnectionClose or: [ response wantsConnectionClose ]
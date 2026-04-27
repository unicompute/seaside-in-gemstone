request handling
writeResponse: response on: streamTransientStackValue
  "Write response to stream and flush the stream"

  response isStreamingResponse
    ifTrue: [ self write: response duringTransactionOn: streamTransientStackValue value ]
    ifFalse: [ response writeOn: streamTransientStackValue value ].
  streamTransientStackValue value flush.
  self logResponse: response
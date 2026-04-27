private
writeResponseBad: exception on: stream
  "When we failed to parse a request, write a bad request response before closing."

  | response |
  response := ZnResponse new
    statusLine: ZnStatusLine badRequest;
    headers: ZnHeaders defaultResponseHeaders;
    entity: (ZnEntity textCRLF: 'Bad Request ' , exception printString);
    yourself.
  response setConnectionClose.
  self
    serve: [ self writeResponse: response on: stream ]
    on: self writeResponseTerminationExceptionSet
    do: [ :ex |  ]
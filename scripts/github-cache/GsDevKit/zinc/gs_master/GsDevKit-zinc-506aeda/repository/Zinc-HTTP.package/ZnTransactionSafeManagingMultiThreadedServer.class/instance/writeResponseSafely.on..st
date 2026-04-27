request handling
writeResponseSafely: response on: streamTransientStackValue
  "Write response to stream, when the connection is closed or times out we ignore this"

  [ self writeResponse: response on: streamTransientStackValue ]
    on: self writeResponseTerminationExceptionSet
    do: [ :exception | 
      self log
        error: exception description
        message: (GsProcess stackReportToLevel: 100) ]
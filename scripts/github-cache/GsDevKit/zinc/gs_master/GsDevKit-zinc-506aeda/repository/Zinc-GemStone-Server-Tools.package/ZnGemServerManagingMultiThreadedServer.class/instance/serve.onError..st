gem server
serve: aBlock onError: beforeUnwindBlock
  "called from within a server:ensure: context"

  ^ self gemServer
    gemServer: aBlock
    exceptionSet: Error
    beforeUnwind: beforeUnwindBlock
gem server
serve: aBlock on: exceptionSet do: beforeUnwindBlock
  "called from within a server:ensure: context"

  ^ self gemServer
    gemServer: aBlock
    exceptionSet: exceptionSet
    beforeUnwind: beforeUnwindBlock
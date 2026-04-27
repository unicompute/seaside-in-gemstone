private
createContinuation: errorDescription
  (self enabled and: [ self enableCreateContinuations ])
    ifTrue: [ 
      GRPlatform current
        doTransaction: [ DebuggerLogEntry createContinuationLabeled: errorDescription ] ]
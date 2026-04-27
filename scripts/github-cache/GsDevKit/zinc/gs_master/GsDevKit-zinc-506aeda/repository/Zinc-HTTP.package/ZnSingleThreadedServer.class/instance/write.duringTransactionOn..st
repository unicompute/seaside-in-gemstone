request handling
write: response duringTransactionOn: stream
  | commitResult |
  System inTransaction
    ifTrue: [ 
      "We already are in a transaction, so just write the response"
      response writeOn: stream.
      ^ true ]
    ifFalse: [ 
      [ 
      System beginTransaction.
      response writeOn: stream ]
        ensure: [ 
          "workaround for Bug 42963: ensure: block executed twice (don't return from ensure: block)"
          commitResult := System commitTransaction ] ].
  ^ commitResult
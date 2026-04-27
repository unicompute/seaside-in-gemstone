transactions
doCommit: commitBlock
  System inTransaction
    ifTrue: [ 
      self gemServer transactionMutex
        critical: [ 
          | commitResult |
          commitBlock value.
          commitResult := System commitTransaction.
          System transactionMode == #'manualBegin'
            ifTrue: [ System beginTransaction ].
          ^ commitResult ] ]
    ifFalse: [ ^ self gemServer doTransaction: commitBlock ]
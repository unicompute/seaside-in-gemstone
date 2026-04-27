as yet unclassified
flush
  "If the other end is connected and we have something
	to send, then we send it and reset the outBuffer."

  (outNextToWrite > 1 and: [ self socket isActive ])
    ifTrue: [ 
      [ self socket sendData: outBuffer count: outNextToWrite - 1 ]
        on: ConnectionTimedOut
        do: [ :ex | 
          shouldSignal
            ifFalse: [ 
              "swallow"
               ] ].
      outNextToWrite := 1 ]
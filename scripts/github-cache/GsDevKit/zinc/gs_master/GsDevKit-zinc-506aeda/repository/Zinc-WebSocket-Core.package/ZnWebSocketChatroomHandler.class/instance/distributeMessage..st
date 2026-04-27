protocol
distributeMessage: message
  "Send message to all client WebSockets that we know."

  "other than logging (which will be committed if running in #manualBegin tranaction mode), 
   no persistent state is changed here"

  lock
    critical: [ 
      webSockets
        do: [ :each | 
          [ 
          each
            logInfo: [ each asOop printString , ' Sending message: ' , message printString ].
          each sendMessage: message.
          each logInfo: [ each asOop printString , ' sent message' ] ]
            on: NetworkError
            do: [ :exception | 
              "We can ignore this (instead of #unregister:-ing the offender), 
					since the listener process (see #value:) will do the right thing"
              each
                logDebug: [ exception printString , ' in ditributeMessage, ignoring' ] ] ] ]
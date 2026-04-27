accessing
event: logEvent
  | category entry label |
  category := logEvent category.
  label := logEvent label.
  entry := category == #'error'
    ifTrue: [ ObjectLogEntry error: label object: logEvent ]
    ifFalse: [ 
      category == #'object'
        ifTrue: [ ObjectLogEntry info: label object: logEvent ]
        ifFalse: [ 
          category == #'debug'
            ifTrue: [ ObjectLogEntry debug: label object: logEvent ]
            ifFalse: [ 
              category == #'transaction'
                ifTrue: [ ObjectLogEntry trace: label object: logEvent ]
                ifFalse: [ ObjectLogEntry info: label object: logEvent ] ] ] ].
  GRPlatform current doTransaction: [ entry addToLog ]
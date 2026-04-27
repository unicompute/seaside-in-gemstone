accessing
error: errorDescription message: message
  self enabled
    ifTrue: [ 
      self announcer
        announce:
          (ZnLogEvent error: errorDescription value message: message value) ]
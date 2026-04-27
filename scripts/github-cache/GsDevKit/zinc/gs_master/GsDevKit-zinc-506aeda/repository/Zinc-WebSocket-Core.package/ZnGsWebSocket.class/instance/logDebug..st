logging
logDebug: message
  self logEvent: [ (ObjectLogEntry debug: message value) addToLog ]
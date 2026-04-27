logging
logInfo: message
  self logEvent: [ (ObjectLogEntry info: message value) addToLog ]
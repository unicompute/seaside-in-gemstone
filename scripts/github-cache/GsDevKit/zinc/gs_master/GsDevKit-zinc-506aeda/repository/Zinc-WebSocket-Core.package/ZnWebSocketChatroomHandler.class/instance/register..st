protocol
register: clientWebSocket
  "persist changes to webSockets"

  lock critical: [ self doCommit: [ webSockets add: clientWebSocket ] ]
protocol
unregister: clientWebSocket
  "persist changes to webSockets"

  lock
    critical: [ self doCommit: [ webSockets remove: clientWebSocket ifAbsent: [  ] ] ]
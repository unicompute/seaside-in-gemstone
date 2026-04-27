accessing
value: webSocket
  "I stream status messages to a WebSocket client, once every second 
	until ConnectionClosed or no longer isConnected"

  [ 
  webSocket gemServer: self gemServer.
  webSocket logInfo: 'Started status streaming'.
  [ 
  webSocket sendMessage: self status.
  (Delay forSeconds: 1) wait.
  webSocket isConnected ]
    whileTrue ]
    on: ConnectionClosed
    do: [ :ignored | webSocket logDebug: 'Ignoring connection close' ].
  webSocket logInfo: 'Stopping status streaming'
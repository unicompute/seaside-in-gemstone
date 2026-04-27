accessing
value: webSocket
  "I implement an echo service conversation as a server:
	reading messages and echoing them back until ConnectionClosed"

  [ 
  webSocket gemServer: self gemServer.
  webSocket
    runWith: [ :message | 
      webSocket logInfo: [ 'Received message: ' , message printString , ', echoing' ].
      webSocket sendMessage: message ] ]
    on: ConnectionClosed
    do: [ :ignored | webSocket logDebug: 'Ignoring connection close, done' ]
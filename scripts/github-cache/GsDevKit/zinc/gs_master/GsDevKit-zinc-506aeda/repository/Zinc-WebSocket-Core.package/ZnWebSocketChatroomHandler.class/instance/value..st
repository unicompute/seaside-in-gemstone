accessing
value: webSocket
  "I implement a simple chat room service as a server:
	distributing incoming messages to all known clients"

  [ 
  webSocket gemServer: self gemServer.
  webSocket logInfo: [ webSocket asOop printString , ' registering' ].
  self register: webSocket.
  webSocket
    runWith: [ :message | 
      webSocket
        logInfo: [ webSocket asOop printString , ' Received message: ' , message printString ].
      self distributeMessage: message.
      webSocket
        logInfo: [ webSocket asOop printString , ' distributed message' ] ] ]
    on: ConnectionClosed
    do: [ :ignored | 
      webSocket logDebug: 'Connection close, cleaning up'.
      self unregister: webSocket ]
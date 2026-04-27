private
readFrame
  "Read and return the next non-control frame. Wait.
	Control frames are handled. ConnectionClosed is signalled when the other end closes."

  | frame |
  frame := ZnWebSocketFrame readFrom: self stream.
  self logInfo: [ self asOop printString , ' got frame..' ].
  frame isControl
    ifTrue: [ 
      self handleControlFrame: frame.
      ^ self readFrame ].
  ^ frame
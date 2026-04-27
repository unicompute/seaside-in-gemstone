protocol
handleControlFrameNoWait
  "Peek for a control frame if any and handle it. Do not wait.
	Return true when a control frame was handled, false otherwise."

  | strm |
  strm := self stream.	"stream iv is wrapped by TransientValue, because GsSocket instances cannot be persisted"
  (strm isDataAvailable and: [ (strm peek bitAnd: 127) > 7 ])
    ifTrue: [ 
      | frame |
      frame := ZnWebSocketFrame readFrom: strm.
      self handleControlFrame: frame.
      ^ true ].
  ^ false
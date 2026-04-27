private
sendFrame: frame
  "Send a single frame, masked when I am in a client role, flush"

  | strm |
  strm := self stream.	"stream iv is wrapped by TransientValue, because GsSocket instances cannot be persisted"
  frame masked: self isClient.
  frame writeOn: strm.
  strm flush
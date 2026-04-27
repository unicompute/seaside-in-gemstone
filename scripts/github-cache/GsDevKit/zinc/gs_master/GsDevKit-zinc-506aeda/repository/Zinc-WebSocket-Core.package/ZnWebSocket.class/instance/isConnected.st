testing
isConnected
  "Return true when I am connected, 
	i.e. not closed and still connected at the socket level"

  | strm |
  strm := self stream.	"stream iv is wrapped by TransientValue, because GsSocket instances cannot be persisted"
  ^ strm notNil and: [ strm isConnected ]
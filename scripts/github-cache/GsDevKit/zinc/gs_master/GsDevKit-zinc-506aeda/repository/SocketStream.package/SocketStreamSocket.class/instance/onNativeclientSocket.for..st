private
onNativeclientSocket: aNativeSocket for: aServerSocket
  "^self
	I initialize myself with the same properties as aServerSocket and with
	aNativeSocket as my underlying socket."

  communicationDomain := aServerSocket communicationDomain.
  socketType := aServerSocket socketType.
  protocolNumber := aServerSocket protocolNumber.
  self _setNoStubbing.	"as long as I am in memory prevent stubbing of my instance variables ... I will stay in memory as long as I am referenced from stack.."
  underlyingSocket := TransientStackValue value: aNativeSocket.	"if I am committed, then do not persist aNativeSocket"
  ^ self
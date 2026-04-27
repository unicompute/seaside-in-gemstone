initialize-release
onNativeSocket: aSocket forDomain: aCommunicationDomain type: aSocketType protocol: aProtocolNumber
  "^self
	I initialize myself as a socket defined by the communications domain, type and protocol.  This
	follows the equivalent of the using the socket()  or socketpair() function."

  communicationDomain := aCommunicationDomain.
  socketType := aSocketType.
  protocolNumber := aProtocolNumber.
  self _setNoStubbing.	"as long as I am in memory prevent stubbing of my instance variables ... I will stay in memory as long as I am referenced from stack.."
  underlyingSocket := TransientStackValue value: aSocket.	"if I am committed, then do not persist aSocket"
  ^ self
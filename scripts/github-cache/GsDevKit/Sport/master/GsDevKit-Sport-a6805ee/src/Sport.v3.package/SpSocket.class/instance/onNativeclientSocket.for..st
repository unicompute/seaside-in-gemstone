private
onNativeclientSocket: aNativeSocket for: aServerSocket 
	"^self
	I initialize myself with the same properties as aServerSocket and with
	aNativeSocket as my underlying socket."

	communicationDomain := aServerSocket communicationDomain.
	socketType := aServerSocket socketType.
	protocolNumber := aServerSocket protocolNumber.
	underlyingSocket := aNativeSocket.
	^self

testing
testEchoSecureWebSocketsDotOrg
	"Needs to be executed in ZnGsWebSocketTests context"
	| webSocket message |
	(Smalltalk at: #'GsSecureSocket') disableCertificateVerificationOnClient.
	webSocket := self webSocketClass to: 'wss://echo.websocket.org'.
	message := 'Greetings from Gemstone Smalltalk @ ' , TimeStamp now printString.
	webSocket sendMessage: message.

	"The following server reply line is not specified in the [RFC6455].
	It is specific to echo.websocket.org server. The server is coded in Go programming language.
	Implementation details:
		- The hash (after by) is the return type of the os.Hostname() function (name string, err error),
		  it returns a string containing the host name reported by the kernel and error if any.
		- The source code: https://github.com/ably/echo.websocket.org/blob/ffe04c5ff499270b04c5bf2a2db2ee30fccee50a/cmd/echo-server/main.go#L147"
	self assert: webSocket readMessage equals: 'Request served by 4d896d95b55478'.

	"The actual response of echo"
	self assert: webSocket readMessage equals: message.
	webSocket close
testing
expectedFailures
	true
		ifTrue: [ 
			"echo.webserver.org is no longer available ... so tests are passing now :). See https://github.com/GsDevKit/zinc/issues/96"
			^ #() ].
	(System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
		<= '3.3.0' asMetacelloVersionNumber
		ifTrue: [ 
			"secure sockets not supported pre-3.3.0"
			^ #(#'testEchoSecureWebSocketsDotOrg') ].
	^ #()
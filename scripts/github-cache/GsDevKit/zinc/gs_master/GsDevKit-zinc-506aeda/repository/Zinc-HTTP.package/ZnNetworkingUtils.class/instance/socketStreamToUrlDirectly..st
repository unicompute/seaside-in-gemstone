public
socketStreamToUrlDirectly: url
	| stream address |
	address := SpIPAddress ipAddressForHostName: url host timeout: self timeout. 
	stream := (self streamClassForScheme: url scheme) 
		openConnectionToHost: address
		port: url portOrDefault
		timeout: self timeout.	
	self setSocketStreamParameters: stream.	
	(#(https wss) includes: url scheme)
		ifTrue:
			[stream
				"Avoid warning about unimplemented selector when Zodiac is not loaded."
				perform: #serverNameIndication:
				with: url host.
			stream
				connect].	
	^ stream

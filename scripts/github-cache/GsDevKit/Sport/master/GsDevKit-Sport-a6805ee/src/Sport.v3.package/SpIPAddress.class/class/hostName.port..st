as yet unclassified
hostName: aHostNameString port: aPortNumber 
	"^an SpSocketAddress
	I translate aHostNameString to an IP address and then create
	a new instance of myself with >>host:port:"

	^aHostNameString == nil
		ifTrue: [ 
			self host: nil
				port: aPortNumber]
		ifFalse: [ 
			self host: (self ipAddressForHostName: aHostNameString timeout: 60)
				port: aPortNumber]

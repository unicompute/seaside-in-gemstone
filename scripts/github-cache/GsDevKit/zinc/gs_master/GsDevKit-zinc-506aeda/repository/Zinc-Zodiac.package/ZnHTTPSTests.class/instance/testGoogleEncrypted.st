testing
testGoogleEncrypted
	| client |
	self ensureSocketStreamFactory.
	self isNativeSSLPluginPresent
		ifFalse: [ ^ self ].
	[ (client := ZnClient new) get: 'https://encrypted.google.com/search?q=Smalltalk' ]
		on: ZnUnknownHttpVersion , ZnTooManyRedirects
		do: [ :ex | 
			Transcript
				cr;
				show: 'google has started to randomly fail requests: ' , ex description.
			^ self ].
	self assert: client isSuccess.
	self assert: (client contents includesSubstring: 'Google').
	self assert: (client contents includesSubstring: 'Smalltalk').
	client close
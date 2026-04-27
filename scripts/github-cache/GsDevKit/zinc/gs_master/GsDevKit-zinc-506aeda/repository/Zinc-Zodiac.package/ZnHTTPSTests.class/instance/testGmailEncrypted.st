testing
testGmailEncrypted
	| client |
	self ensureSocketStreamFactory.
	self isNativeSSLPluginPresent
		ifFalse: [ ^ self ].
	[ (client := ZnClient new) get: 'https://www.gmail.com' ]
		on: ZnUnknownHttpVersion , ZnTooManyRedirects
		do: [ :ex | 
			Transcript
				cr;
				show: 'gmail has started to randomly fail requests: ' , ex description.
			^ self ].
	self assert: client isSuccess.
	self assert: (client contents includesSubstring: 'Google').
	self assert: (client contents includesSubstring: 'mail').
	client close
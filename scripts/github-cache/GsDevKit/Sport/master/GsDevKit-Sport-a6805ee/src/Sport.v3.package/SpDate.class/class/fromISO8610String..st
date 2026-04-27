instance creation
fromISO8610String: aString
	^self fromISO8610Stream: aString readStream

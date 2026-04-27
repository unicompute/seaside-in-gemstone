services-io
waitForReadDataUpToMs: aNumberOfMilliseconds 
	"^a Boolean
	I return true if we think data became available within aNumberOfMilliseconds, and
	false if we timed out."

	^self underlyingSocket readWillNotBlockWithin: aNumberOfMilliseconds

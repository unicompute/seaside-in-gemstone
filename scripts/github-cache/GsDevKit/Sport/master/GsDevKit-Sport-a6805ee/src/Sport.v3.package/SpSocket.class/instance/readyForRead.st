services-io
readyForRead
	"^a Boolean
I return true if a read operation will return some number of bytes."

	^self underlyingSocket readWillNotBlock

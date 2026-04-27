services-io non-blocking
waitForNonBlockingReadActivityUpToMs: aNumberOfMilliseconds 
	"^a Boolean
I return true if there has been some read related activity on my underlying socket, otherwise false.  Note that activity may not mean that data is available.  It may just mean that the socket is in a new (perhaps error) state."

	| ans |
	(ans := self underlyingSocket readWillNotBlockWithin: aNumberOfMilliseconds) == nil
		ifTrue: [ ^true ].
	^ans
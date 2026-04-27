services-status
close
	"^self
	The same as the close() posix function."

	self underlyingSocket close.
	^self

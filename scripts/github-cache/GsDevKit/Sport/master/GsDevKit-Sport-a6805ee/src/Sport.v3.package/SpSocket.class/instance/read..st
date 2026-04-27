services-io
read: targetNumberOfBytes 
	"^a ByteArray
	I attempt to read the targetNumberOfBytes from my underlying socket.  If the targetNumberOfBytes
	are not available, I return what I can get.
	Note that here I make sure that I behave in the same way as VisualWorks - i.e. I make blocking
	with respect to the Smalltalk Pocess.  So if a Smalltalk process invokes this method it will block until
	a read is possible - however, the other processes in the Gem will *not* block."
	"Janko Mivsek feb08: changes to avoid 100%CPU load - using readWillNotBlockWithin:"

	| targetByteArray numberOfBytesActuallyRead |
	self underlyingSocket readWillNotBlockWithin: -1.  "wait until data arrive"
	targetByteArray := ByteArray new: targetNumberOfBytes.
	numberOfBytesActuallyRead := self underlyingSocket 
				read: targetNumberOfBytes
				into: targetByteArray.
	^numberOfBytesActuallyRead > 0
		ifTrue: [targetByteArray copyFrom: 1 to: numberOfBytesActuallyRead]
		ifFalse: [ByteArray new]

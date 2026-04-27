printing
asISO8610String
	|targetStream|
	targetStream := WriteStream on: String new.
	self asISO8610StringOn: targetStream.
	^targetStream contents

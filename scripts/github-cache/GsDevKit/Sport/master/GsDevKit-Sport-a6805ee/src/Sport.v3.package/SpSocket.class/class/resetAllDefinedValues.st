private
resetAllDefinedValues
	"^self
	I simply set the all the symbol dictionaries containing defined values to
	nil, forcing them to be re-initialized on demand."

	"SpSocket resetAllDefinedValues"

	addressFamilies := nil.
	protocolFamilies := nil.
	socketTypes := nil.
	^self

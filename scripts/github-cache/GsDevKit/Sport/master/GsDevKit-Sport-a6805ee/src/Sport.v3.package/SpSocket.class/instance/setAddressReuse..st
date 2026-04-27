services-options
setAddressReuse: aBoolean 
	"^self
	c.f. self class >>socketOptions and self >>setOptionForLevel:optionID:value:
	If a boolean is true, I set address reuse on, otherwise I set address reuse off."

	^self underlyingSocket option: 'REUSEADDR' put: aBoolean

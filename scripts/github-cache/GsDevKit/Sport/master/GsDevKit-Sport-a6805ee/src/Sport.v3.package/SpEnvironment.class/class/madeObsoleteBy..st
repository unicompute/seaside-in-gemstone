development
madeObsoleteBy: aBlock 
	"^an Object
I cause halt the code and ask the developer to use the code in aBlock, rather than the obsolete code."

	(self isHeadless or: [self isGemStone]) 
		ifFalse: 
			[1 
				halt: 'please use the code in the block, not the obsolete code - thanks.'].
	^aBlock value

instance creation
for: aBlock onAnyErrorDo: exceptionBlock 
	"^an Object 
	I execute aBlock and if there is any error I evalute exceptionBlock."

	^aBlock
		on: Error
		do: exceptionBlock.

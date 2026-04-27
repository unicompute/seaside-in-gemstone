private
parseDateFromISO8601Stream: sourceStream 
	"^a Date or nil
	I parse an ISO 8601 date from sourceStream.  If there are any parsing
	problems, I return nil."

	"SpDate parseDateFromISO8601Stream: (ReadStream on: '2004-01-42')"

	| yyyy mm dd |
	yyyy := self integerOfLength: 4 FromString: (sourceStream upTo: $-).
	mm := self integerOfLength: 2 FromString: (sourceStream upTo: $-).
	sourceStream atEnd ifFalse: [
		dd := self integerOfLength: 2 FromString: sourceStream upToEnd].
	(yyyy isNil or: [mm isNil or: [dd isNil]]) ifTrue: [^nil].
	^SpExceptionContext 
		for: 
			[Date 
				newDay: dd
				monthNumber: mm
				year: yyyy]
		on: SpError
		do: [:ex | nil]

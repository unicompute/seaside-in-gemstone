instance creation
fromISO8610Stream: aStream 
	| date |
	date := SpExceptionContext 
				for: [self parseDateFromISO8601Stream: aStream]
				on: SpError
				do: [:ex | nil].
	^date isNil ifTrue: [nil] ifFalse: [self onDate: date]

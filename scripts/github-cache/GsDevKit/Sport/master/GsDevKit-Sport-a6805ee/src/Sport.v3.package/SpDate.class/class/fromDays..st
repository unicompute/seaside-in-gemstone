instance creation
fromDays: numberOfDays
	"Answer with an instance of Date that is dayCount days since 1901 began."
	"This is based on the VisualWorks implementation."
	| aDate correction |
	aDate := self
		newDay: 1 + (numberOfDays rem: 1461)
							"There are 1461 days in a 4-year cycle.
							 This doesn't handle leap-centuries quite right:
							 we fix this up below."
		year: 1901 + ((numberOfDays quo: 1461) * 4).
	"Now correct for leap-centuries."
	correction := numberOfDays - aDate asDays.
	^correction = 0
		ifTrue: [aDate]
		ifFalse: [aDate addDays: correction]

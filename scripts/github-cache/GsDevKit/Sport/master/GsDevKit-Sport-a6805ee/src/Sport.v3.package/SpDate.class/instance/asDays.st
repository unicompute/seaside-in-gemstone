converting
asDays
	"^an Integer
	I return the integer number of days between January 1, 1901 and
	the date I represent. 
	This is the VisualWorks implementation."

	| yearIndex |
	yearIndex := self year - 1901.
	^yearIndex * 365  "elapsed years"
		+ (yearIndex // 4)  "ordinary leap years"
		+ ((yearIndex + 300) // 400)  "leap centuries, first one is 2000, i.e. yearIndex = 99"
		- (yearIndex // 100)  "non-leap centuries"
		+ self julianDay - 1

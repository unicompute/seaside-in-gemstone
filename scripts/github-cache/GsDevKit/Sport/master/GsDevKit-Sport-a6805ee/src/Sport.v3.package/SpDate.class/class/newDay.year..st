instance creation
newDay: julianDay year: year
"^an SpDate
I return a new instance of myself."

	^self onDate: (Date newDay: julianDay year: year)

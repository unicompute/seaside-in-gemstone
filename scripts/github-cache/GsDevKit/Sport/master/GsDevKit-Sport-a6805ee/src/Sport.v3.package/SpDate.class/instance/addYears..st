services
addYears: anInteger 
	"^an OSkDate
I don't change the date I represent.  Rather, I create a new date which represents my date offset by anInteger years.  If we are adding years to the 29th Feb, we need to worry about leap years. "

	^self class onDate: (self underlyingDate addYears: anInteger)

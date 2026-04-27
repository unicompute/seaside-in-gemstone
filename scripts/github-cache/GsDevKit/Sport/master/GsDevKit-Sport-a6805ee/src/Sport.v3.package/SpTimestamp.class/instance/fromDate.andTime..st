initialize-release
fromDate: aDate andTime: aTime 
	"^self
Initialize myself on the basis of aDate and aTime."

	underlyingTimestamp := DateTime newWithDate: aDate time: aTime.
	^self

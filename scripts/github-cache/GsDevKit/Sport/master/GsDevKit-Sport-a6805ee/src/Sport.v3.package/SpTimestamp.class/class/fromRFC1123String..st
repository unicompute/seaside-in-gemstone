instance creation
fromRFC1123String: aString 
	"^an SpTimestamp"

	| sourceStream dd mmm yyyy time |
	^SpExceptionContext 
		for: 
			[sourceStream := ReadStream on: aString.
			sourceStream upTo: Character space.
			dd := sourceStream upTo: Character space.
			mmm := sourceStream upTo: Character space.
			yyyy := sourceStream upTo: Character space.
			time := sourceStream upTo: Character space.
			self fromDate: (Date 
						newDay: dd asNumber
						month: mmm
						year: yyyy asNumber)
				andTime: (Time fromString:  time)]
		onAnyExceptionDo: 
			[:exception | SpError raiseSignal: 'Error parsing RFC1123 date: ' , aString]

printing
asRFC1123StringOn: targetStream
	"^a self
	I write a string representing my underlying DataTime of the form:
		Tue, 23 Mar 2004 15:24:12 GMT
	to targetStream"
	"SpTimestamp now asRFC1123String"

	targetStream
		nextPutAll: (self class threeCharacterWeekDayNames 
					at: self underlyingTimestamp dayOfWeek);
		nextPutAll: ', ';
		nextPutAll: (self underlyingTimestamp
					asStringUsingFormat: #(1 2 3 $  2 1 $: true true false));
		nextPutAll: ' GMT'.
	^self

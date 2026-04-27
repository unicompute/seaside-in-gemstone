instance creation
on: subjectAddress for: aSocket 
	"^an SpSocketAddress
	Well, in the future there may be more than one kind of socket address,
	but for now there is just SpIPAddress, so I return one of those on the 
	details embodied in the subjectAddress. 
	No use is made of aSocket as yet, but it will be useful when there
	are more kinds of socket address supported."

	^SpIPAddress host: subjectAddress hostAddress port: subjectAddress port

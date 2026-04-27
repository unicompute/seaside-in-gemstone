services
newSocketPair
	"^an Array
	I return an array containing two SpSockets each representing one end of a
	#PF_UNIX connection."

	^self socketPairForDomain: #PF_UNIX type: #SOCK_STREAM

services
writeStackDumpForException: anException context: aContext to: targetStream 

	targetStream nextPutAll: (GsProcess stackReportToLevel: 50).
	^self

accessing
connections

	"if I am committed, then do not persist collection"
	^SessionTemps current
		at: #ZnGemServerManagingMultiThreadedServer_connections
		ifAbsentPut:[ OrderedCollection new ]

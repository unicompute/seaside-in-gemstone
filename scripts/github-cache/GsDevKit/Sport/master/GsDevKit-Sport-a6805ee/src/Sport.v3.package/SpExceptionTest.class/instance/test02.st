tests
test02
	"Catch an exception"

	| caughtIt |
	caughtIt := false.
	SpExceptionContext 
		for: [ SpError raiseSignal ]
		on: SpError
		do: [:ex| caughtIt := true ].
	self assert: caughtIt

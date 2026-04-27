tests
test05
	"Catch an exception by specifying a superclass of the raised exception class."

	| caughtIt |
	caughtIt := false.
	SpExceptionContext 
		for: [ SpError raiseSignal ]
		on: SpAbstractError
		do: [:ex| caughtIt := true ].
	self assert: caughtIt.
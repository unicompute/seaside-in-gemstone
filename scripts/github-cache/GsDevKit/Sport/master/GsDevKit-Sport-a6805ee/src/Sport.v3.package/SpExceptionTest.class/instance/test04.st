tests
test04
	"Catch an exception raised in a handle block"

	| caughtIt |
	caughtIt := false.
	SpExceptionContext 
		for: [ SpExceptionContext 
				for: [ SpError raiseSignal ]
				on: SpError
				do: [:ex | SpError raiseSignal ]]
		on: SpError
		do: [:ex| caughtIt := true ].
	self assert: caughtIt

	

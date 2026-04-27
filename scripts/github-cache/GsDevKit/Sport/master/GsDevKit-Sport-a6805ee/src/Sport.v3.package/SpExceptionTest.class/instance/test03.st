tests
test03
	"Raise an exception raised in a handle block"

	self should: [
			SpExceptionContext 
				for: [ SpError raiseSignal ]
				on: SpError
				do: [:ex | SpError raiseSignal ]] 
		raise: SpError

	

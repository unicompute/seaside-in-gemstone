testing
test04
	"Catch an exception raised in a handle block"

	"SpExceptionTests test04"

	SpExceptionContext 
		for: [self test03]
		on: SpError
		do: [:ex| ex halt]

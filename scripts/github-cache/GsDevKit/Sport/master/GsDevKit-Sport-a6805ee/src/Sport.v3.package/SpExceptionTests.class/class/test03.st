testing
test03
	"Raise an exception raised in a handle block"

	"SpExceptionTests test03"

	SpExceptionContext 
		for: [self test01]
		on: SpError
		do: [:ex| self test01]

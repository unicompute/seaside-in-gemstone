testing
test05
	"Catch an exception by specifying a superclass of the raised exception class."

	"SpExceptionTests test05"

	SpExceptionContext 
		for: [self test01]
		on: SpAbstractError
		do: [:ex| ex halt]

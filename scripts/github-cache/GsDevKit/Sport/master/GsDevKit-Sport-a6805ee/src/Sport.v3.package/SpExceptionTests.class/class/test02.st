testing
test02
	"Catch an exception"

	"SpExceptionTests test02"

	SpExceptionContext 
		for: [self test01]
		on: SpError
		do: [:ex| ex halt]

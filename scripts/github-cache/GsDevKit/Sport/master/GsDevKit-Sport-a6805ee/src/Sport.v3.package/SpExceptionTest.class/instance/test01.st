tests
test01
	"Just throw an exception"

	self should: [ SpError raiseSignal ] raise: SpError

services-status
acceptRetryingIfTransientErrors
	"^an SpSocket
	I try to do an accept.  If I get an exception which is 'transient' I retry.
	... except that in GemStone, I don't do that - because I don't know how."

	^self accept

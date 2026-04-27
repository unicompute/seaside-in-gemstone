native exceptions
brokenPipeException
	"I return the exception that get's thrown when a socket connection gets 
	broken. This is used in PostgreSQLConnection>>close (which doesn't exist
	in GemStone)."

	^Error

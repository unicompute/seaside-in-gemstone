defined symbols
fileControlOptions
	"^an IdentityDictionary
	I return the dictionary mapping each defined file control symbol to it's numeric
	value.  See fcntl.h and look for the at: #O_xxx lines.
	Really this is here for the O_NONBLOCK option which sets the fd (file descriptor)
	of a socket to non-blocking mode when used in an fcntl() function.
	If you modify this method, evaluate the following:
		'SpSocket resetAllDefinedValues' "

	fileControlOptions isNil 
		ifTrue: 
			[fileControlOptions := (IdentityDictionary new)
						at: #O_ACCMODE put: 0003;
						at: #O_RDONLY put: 00;
						at: #O_WRONLY put: 01;
						at: #O_RDWR put: 02;
						at: #O_CREAT put: 0100;
						at: #O_EXCL put: 0200;
						at: #O_NOCTTY put: 0400;
						at: #O_TRUNC put: 01000;
						at: #O_APPEND put: 02000;
						at: #O_NONBLOCK put: 04000;
						at: #O_NDELAY put: 04000;
						at: #O_SYNC put: 010000;
						at: #FASYNC put: 020000;
						at: #O_DIRECT put: 040000;
						at: #O_LARGEFILE put: 0100000;
						at: #O_DIRECTORY put: 0200000;
						at: #O_NOFOLLOW put: 0400000;
						yourself].
	^fileControlOptions

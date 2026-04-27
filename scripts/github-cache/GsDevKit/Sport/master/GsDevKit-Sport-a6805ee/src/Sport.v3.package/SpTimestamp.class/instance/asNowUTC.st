initialize-release
asNowUTC
	"^self
	Cheat for now and assumen that DateTime>>now is UTC."

	underlyingTimestamp := DateTime now.
	^self

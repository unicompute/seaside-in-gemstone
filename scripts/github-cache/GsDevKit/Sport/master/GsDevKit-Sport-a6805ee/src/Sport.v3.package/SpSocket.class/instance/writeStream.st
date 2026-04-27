services-streams
writeStream
	"^nil
While this is convinient, it would mean that sockets would depend on streams, and we want to avoid that.
Use {my stream class} on: {my socket} instead."

	^self shouldNotImplement

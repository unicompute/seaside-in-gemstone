private
onNativeclientSocket: aNativeSocket for: aServerSocket 
	"^an SpSocket
I create a new instance of my self at the request of aServerSocket  where
this new instance will be a connected client socket (connected via aNativeSoket)."

	^self new onNativeclientSocket: aNativeSocket for: aServerSocket

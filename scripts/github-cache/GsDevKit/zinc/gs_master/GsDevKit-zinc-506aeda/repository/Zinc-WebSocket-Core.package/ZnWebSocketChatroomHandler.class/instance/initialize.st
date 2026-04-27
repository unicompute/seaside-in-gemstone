initialize-release
initialize
	webSockets := OrderedCollection new.
	lock := TransientMutex new
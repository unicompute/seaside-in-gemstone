running
setUp
	| port |
	super setUp.
	ZnServer defaultServerClass initialize.
	port := 1700 + 100 atRandom.
	GemServerRegistry removeGemServerNamed: 'ZnGsExampleStorageRestServer'.
	gemServer := (self createGemServer: port)
		logToTranscript;
		logToObjectLog;
		logEverything;
		yourself.
	self startGems.
	client := self
		createClientFor:
			(ZnUrl new
				scheme: #'http';
				host: 'localhost';
				port: port;
				yourself)
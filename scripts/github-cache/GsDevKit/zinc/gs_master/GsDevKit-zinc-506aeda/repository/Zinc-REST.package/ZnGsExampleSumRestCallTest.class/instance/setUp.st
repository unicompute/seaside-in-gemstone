running
setUp
  | port |
  super setUp.
  ZnServer defaultServerClass initialize.
  port := 1700 + 10 atRandom.
  GemServerRegistry removeGemServerNamed: 'ZnGsExampleStorageRestServer'.
  gemServer := (ZnGemServer register: 'ZnGsExampleStorageRestServer' on: {port})
    logToTranscript;
    logToObjectLog;
    logEverything;
    delegate:
        (ZnRestServerDelegate new
            uriSpace:
                (ZnCallHierarchyRestUriSpace new
                    rootClass: ZnExampleSumRestCall;
                    yourself);
            yourself);
    yourself.
  gemServer restartGems.
  (Delay forSeconds: 3) wait.
  client := self
    createClientFor:
      (ZnUrl new
        scheme: #'http';
        host: 'localhost';
        port: port;
        yourself)
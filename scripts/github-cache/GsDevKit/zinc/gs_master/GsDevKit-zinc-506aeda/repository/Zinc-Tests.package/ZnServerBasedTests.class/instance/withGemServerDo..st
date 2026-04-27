private
withGemServerDo: block
  | gemServer |
  gemServer := self createBasicGemServer.
  TranscriptProxy proxyTranscript ~~ nil
    ifTrue: [ 
      "interactive tests, log to Object Log ... 
       avoid network delay associated with each Transcript show:"
      gemServer logToObjectLog ]
    ifFalse: [ 
      "non-interactive tests, log to Transcript ... gem log"
      gemServer logToTranscript ].
  ^ gemServer
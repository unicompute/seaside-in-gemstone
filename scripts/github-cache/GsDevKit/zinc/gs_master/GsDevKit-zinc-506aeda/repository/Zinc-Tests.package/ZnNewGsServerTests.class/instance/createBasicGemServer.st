private
createBasicGemServer
  | gemServer |
  gemServer := super createBasicGemServer.
  self interactiveRemoteServer
    ifTrue: [ gemServer interactiveMode: true ].
  ^ gemServer
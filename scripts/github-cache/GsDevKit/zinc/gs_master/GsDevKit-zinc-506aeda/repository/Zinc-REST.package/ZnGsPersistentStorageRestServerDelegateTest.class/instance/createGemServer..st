private
createGemServer: port
  | gs |
  gs := super createGemServer: port.
  self interactiveRemoteServer
    ifTrue: [ gs interactiveMode: true ].
  ^ gs
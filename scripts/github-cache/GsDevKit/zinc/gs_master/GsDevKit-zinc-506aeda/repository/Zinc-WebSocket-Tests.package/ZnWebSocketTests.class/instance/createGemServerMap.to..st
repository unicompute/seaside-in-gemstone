private
createGemServerMap: prefix to: handler
  | gemServer |
  gemServer := (ZnNewGemServer register: self gemServerName on: #(1701))
    logToObjectLog;
    logEverything;
    delegate: (self delegateClass map: prefix to: handler);
    yourself.
  self interactiveRemoteServer
    ifTrue: [ gemServer interactiveMode: true ].
  ^ gemServer
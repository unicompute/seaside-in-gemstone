public
handleRequest: request
  " not recommended ... see handleRequest: request gemServer: gemServer"

  | response |
  GRPlatform current doTransaction: [ response := super handleRequest: request ].
  ^ response
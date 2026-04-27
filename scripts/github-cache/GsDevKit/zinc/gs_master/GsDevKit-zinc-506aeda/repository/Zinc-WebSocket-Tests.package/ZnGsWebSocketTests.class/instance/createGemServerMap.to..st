private
createGemServerMap: prefix to: handler
  | gemServer |
  gemServer := super createGemServerMap: prefix to: handler.
  handler gemServer: gemServer.
  System commitTransaction.
  ^ gemServer
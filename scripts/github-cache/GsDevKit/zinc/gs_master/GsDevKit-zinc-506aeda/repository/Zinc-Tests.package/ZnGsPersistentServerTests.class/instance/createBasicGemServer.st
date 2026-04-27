private
createBasicGemServer
  | gemServer |
  gemServer := super createBasicGemServer.
  gemServer delegate: ZnDefaultGsTransactionalServerDelegate new.
  ^ gemServer
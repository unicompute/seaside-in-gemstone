private
runStaticRemoteGemServer: gemServer during: block
  "ZnNewGsServerTests staticRemoteServer: true.
   ZnNewGsServerTests staticRemoteServer: false.

  ZnNewGsServerTests interactiveRemoteServer: true.
  ZnNewGsServerTests interactiveRemoteServer: false."

  "mount @/sys/stone/dirs/GsApplicationTools/tode /home gemserver"

  "abort; /home/gemserver/example --start=ZnServerBasedTestServer"

  "limit autoCommit false; eval `System transactionMode: #manualBegin` /home/gemserver/example --start=ZnServerBasedTestServer"

  System commitTransaction.
  self
    notify:
      'evaluate on server: abort; /home/gemserver/example --start=ZnServerBasedTestServer'.
  [ block cull: gemServer ]
    ensure: [ gemServer unregister ]
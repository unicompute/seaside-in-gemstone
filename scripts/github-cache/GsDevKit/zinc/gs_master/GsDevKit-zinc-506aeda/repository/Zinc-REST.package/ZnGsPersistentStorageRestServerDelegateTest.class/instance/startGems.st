private
startGems
  "ZnGsPersistentStorageRestServerDelegateTest staticRemoteServer: true.
   ZnGsPersistentStorageRestServerDelegateTest staticRemoteServer: false.

  ZnGsPersistentStorageRestServerDelegateTest interactiveRemoteServer: true.
  ZnGsPersistentStorageRestServerDelegateTest interactiveRemoteServer: false."

  "mount @/sys/stone/dirs/GsApplicationTools/tode /home gemserver"

  "abort; /home/gemserver/example --start=ZnGsExampleStorageRestServer"

  "limit autoCommit false; eval `System transactionMode: #manualBegin` /home/gemserver/example --start=ZnGsExampleStorageRestServer"

  self staticRemoteServer
    ifFalse: [ ^ super startGems ].
  self
    notify:
      'evaluate on server: abort; /home/gemserver/example --start=ZnServerBasedTestServer'
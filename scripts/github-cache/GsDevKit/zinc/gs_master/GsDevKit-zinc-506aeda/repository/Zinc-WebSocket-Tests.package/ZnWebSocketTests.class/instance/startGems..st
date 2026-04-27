private
startGems: gemServer
  "ZnWebSocketTests staticRemoteServer: true.
   ZnWebSocketTests interactiveRemoteServer: true.

   ZnWebSocketTests staticRemoteServer: false.
   ZnWebSocketTests interactiveRemoteServer: false."

  "mount @/sys/stone/dirs/GsApplicationTools/tode /home gemserver"

  "abort; /home/gemserver/example --start=ZincWebSocketGemServer"

  "abort;limit autoCommit false; eval `System transactionMode: #manualBegin` /home/gemserver/example --start=ZincWebSocketGemServer"

  self staticRemoteServer
    ifFalse: [ 
      gemServer restartGems.
      (Delay forSeconds: 3) wait.
      ^ self ].
  self
    notify:
      'evaluate on server: abort; /home/gemserver/example --start=' , gemServer name
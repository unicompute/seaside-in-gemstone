private
runGemServer: gemServer during: block
  self staticRemoteServer
    ifTrue: [ ^ self runStaticRemoteGemServer: gemServer during: block ].
  super runGemServer: gemServer during: block
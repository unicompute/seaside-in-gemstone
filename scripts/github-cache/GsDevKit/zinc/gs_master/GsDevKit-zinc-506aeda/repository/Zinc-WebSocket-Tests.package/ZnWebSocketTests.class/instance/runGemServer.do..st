private
runGemServer: gemServer do: aBlock
  [ 
  self startGems: gemServer.	"does a commit"
  aBlock value ]
    ensure: [ 
      self stopGems: gemServer.
      gemServer unregister ]
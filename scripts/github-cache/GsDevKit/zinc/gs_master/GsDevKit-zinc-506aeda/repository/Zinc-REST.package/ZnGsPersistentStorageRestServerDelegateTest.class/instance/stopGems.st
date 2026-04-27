private
stopGems
  self staticRemoteServer
    ifFalse: [ ^ super stopGems ]
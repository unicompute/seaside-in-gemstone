private
createBasicGemServer
  ^ (self gemServerClass register: self gemServerName on: {(self port)})
    logToObjectLog;
    logEverything;
    yourself
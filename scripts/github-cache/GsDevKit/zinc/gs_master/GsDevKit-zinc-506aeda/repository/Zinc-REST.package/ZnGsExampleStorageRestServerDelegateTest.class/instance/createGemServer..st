private
createGemServer: port
  ^ (self gemServerClass register: 'ZnGsExampleStorageRestServer' on: {port})
    logToTranscript;
    logToObjectLog;
    logEverything;
    delegate: self delegateClass new;
    yourself
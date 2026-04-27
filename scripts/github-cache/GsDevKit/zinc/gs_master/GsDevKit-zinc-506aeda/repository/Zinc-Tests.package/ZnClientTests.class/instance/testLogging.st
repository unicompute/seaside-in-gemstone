testing
testLogging
  | client memoryLogger |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  memoryLogger := ZnMemoryLogger new.
  (client := ZnClient new) beOneShot.
  client log addListener: memoryLogger.
  client get: 'http://zn.stfx.eu/zn/small.html'.
  client close.
  self deny: memoryLogger logEvents isEmpty
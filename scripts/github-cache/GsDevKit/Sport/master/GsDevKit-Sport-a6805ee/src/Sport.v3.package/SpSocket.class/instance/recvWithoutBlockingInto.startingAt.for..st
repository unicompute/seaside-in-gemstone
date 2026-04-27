services-io non-blocking
recvWithoutBlockingInto: aByteArray startingAt: startIndex for: aNumberOfOctets
  | ans |
  (ans := self underlyingSocket readWillNotBlock) == nil
    ifTrue: [ 
      ^ SpSocketError
        raiseSignal:
          'Socket recv error: ' , self underlyingSocket lastErrorString asString ].
  ans
    ifFalse: [ ^ 0 ].	"since read will not block, it's okay to make the blocking read call"
  ^ self readInto: aByteArray startingAt: startIndex for: aNumberOfOctets
accessing
object: anObject
  self enabled
    ifTrue: [ self announcer announce: (ZnLogEvent object: anObject value) ]
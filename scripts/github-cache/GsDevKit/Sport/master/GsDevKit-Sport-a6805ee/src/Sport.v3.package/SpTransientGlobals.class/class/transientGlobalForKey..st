accessing
transientGlobalForKey: aKey

| d |
d := self transientGlobalNamed: #'Sport-ClassDefaults'.
d == nil 
  ifTrue: [
    ^nil
  ].
^d at: aKey ifAbsent: [nil].
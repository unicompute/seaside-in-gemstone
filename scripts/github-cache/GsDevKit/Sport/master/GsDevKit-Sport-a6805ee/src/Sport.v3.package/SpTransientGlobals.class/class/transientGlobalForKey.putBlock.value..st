accessing
transientGlobalForKey: aKey putBlock: putBlockBlock value: aValue

| d |
d := self transientGlobalNamed: #'Sport-ClassDefaults'.
d == nil 
  ifTrue: [
    d := Dictionary new.
    self transientGlobals at: #'Sport-ClassDefaults' put: d.
  ].
^d at: aKey put: aValue.
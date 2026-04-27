accessing
transientGlobalForKey: aKey toAccess: accessBlock toStore: storeBlock toCreate: createBlock 
| d default |
d := self transientGlobalNamed: #'Sport-ClassDefaults'.
d == nil 
  ifTrue: [
    d := Dictionary new.
    self transientGlobals at: #'Sport-ClassDefaults' put: d.
  ].
default := d at: aKey ifAbsent: [nil].
default == nil 
  ifTrue: [
    default := createBlock value.
    d at: aKey put: default].
^default
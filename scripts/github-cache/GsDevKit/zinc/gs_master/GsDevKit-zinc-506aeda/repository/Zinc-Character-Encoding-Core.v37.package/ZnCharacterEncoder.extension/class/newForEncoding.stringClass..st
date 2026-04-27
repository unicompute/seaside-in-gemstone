*zinc-character-encoding-core
newForEncoding: string stringClass: stringClass
  "Return a new character encoder object for an encoding described by string.
	Search for a subclass that handles it and delegate (subclassResponsibility)."

  | concreteSubclass |
  concreteSubclass := self allSubclasses
    detect: [ :each | each handlesEncoding: string ]
    ifNone: [ ^ ZnNullEncoder new ].
  ^ concreteSubclass newForEncoding: string stringClass: stringClass
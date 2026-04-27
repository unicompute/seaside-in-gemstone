private
prefix: orderedCollection
  (orderedCollection isKindOf: OrderedCollection)
    ifFalse: [ self halt ].
  prefix := orderedCollection
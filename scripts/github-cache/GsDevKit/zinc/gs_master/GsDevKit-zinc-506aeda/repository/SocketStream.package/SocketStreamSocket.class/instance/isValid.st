as yet unclassified
isValid
  ^ self underlyingSocket notNil and: [ self underlyingSocket isActive ]
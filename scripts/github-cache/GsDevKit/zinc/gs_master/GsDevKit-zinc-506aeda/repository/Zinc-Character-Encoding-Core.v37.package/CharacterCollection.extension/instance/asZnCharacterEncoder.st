*zinc-character-encoding-core
asZnCharacterEncoder
  "Return a ZnCharacterEncoder instance using the receiver as identifier"

  " 'UTF-8' asZnCharacterEncoder "

  (self select: [ :each | each isAlphaNumeric ]) asLowercase = 'utf8'
    ifTrue: [ ^ ZnUTF8Encoder new ]
    ifFalse: [ 
      (self select: [ :each | each isAlphaNumeric ]) asLowercase = '8bit'
        ifFalse: [ ZnNullEncoder new ] ].
  ^ Zn8BITEncoder new
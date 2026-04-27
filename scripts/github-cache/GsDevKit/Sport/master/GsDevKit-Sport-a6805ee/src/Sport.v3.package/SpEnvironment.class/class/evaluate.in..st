compiling
evaluate: aString in: anEnvironment
  "Used by Swazoo"

  ^ self
    evaluate: aString
    receiver: nil
    in: (anEnvironment ifNil: [ System myUserProfile symbolList ])
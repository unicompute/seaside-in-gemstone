options
gemServerOptions: aGemServerOptionsDictionary
  "apply options from aGemServerOptionsDictionary"

  aGemServerOptionsDictionary
    keysAndValuesDo: [ :key :value | self optionAt: key put: value ]
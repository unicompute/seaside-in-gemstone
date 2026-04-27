running
setUp
  super setUp.
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the setup for pre-3.1 GemStone versions"
      ^ self ].
  GsSecureSocket disableCertificateVerificationOnClient
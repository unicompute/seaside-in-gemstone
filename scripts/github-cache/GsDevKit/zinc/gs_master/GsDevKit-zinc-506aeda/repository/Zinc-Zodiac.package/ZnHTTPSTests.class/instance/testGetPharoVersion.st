testing
testGetPharoVersion
  | client lastBuildVersion version |
  true
    ifTrue: [ 
      "https://ci.inria.fr/pharo/job/Pharo-6.0/lastSuccessfulBuild/api/xml?xpath=/*/fullDisplayName gets error when hit from web browser, so this url isn't a good test case anymore"
      ^ self ].
  self ensureSocketStreamFactory.
  self isNativeSSLPluginPresent
    ifFalse: [ ^ self ].
  lastBuildVersion := (client := ZnClient new)
    beOneShot;
    get:
        'https://ci.inria.fr/pharo/job/Pharo-6.0/lastSuccessfulBuild/api/xml?xpath=/*/fullDisplayName'.
  self assert: client isSuccess.
  self assert: (client response contentType matches: ZnMimeType applicationXml).
  self assert: client response contentLength > 0.
  self assert: lastBuildVersion notNil.
  self assert: lastBuildVersion isString.
  self assert: lastBuildVersion size > 0.
  version := (lastBuildVersion copyAfter: $>) copyUpTo: $<.
  self deny: version isEmpty
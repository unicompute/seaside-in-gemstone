running
setUp
  super setUp.
  server := ZnServer startOn: 1700 + 10 atRandom.
  server delegate: ZnExampleStorageRestServerDelegate new.
  client := self createClientFor: server localUrl
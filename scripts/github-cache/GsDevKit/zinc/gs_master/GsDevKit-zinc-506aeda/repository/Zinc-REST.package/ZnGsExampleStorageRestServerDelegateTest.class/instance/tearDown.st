running
tearDown
  super tearDown.
  self stopGems.
  GemServerRegistry removeGemServerNamed: 'ZnGsExampleStorageRestServer'
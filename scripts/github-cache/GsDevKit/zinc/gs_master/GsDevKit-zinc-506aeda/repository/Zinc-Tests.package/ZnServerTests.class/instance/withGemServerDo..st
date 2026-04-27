private
withGemServerDo: block
  | gemServer |
  gemServer := super withGemServerDo: block.
  self runGemServer: gemServer during: block
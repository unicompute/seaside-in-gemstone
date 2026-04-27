private
withGemServerMaximumEntitySize: maximumEntitySize do: block
  | gemServer |
  gemServer := super withGemServerDo: block.
  gemServer maximumEntitySize: maximumEntitySize.
  self runGemServer: gemServer during: block
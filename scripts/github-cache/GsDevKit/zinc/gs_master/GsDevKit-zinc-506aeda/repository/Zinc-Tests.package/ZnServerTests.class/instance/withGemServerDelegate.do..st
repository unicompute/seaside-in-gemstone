private
withGemServerDelegate: delegate do: block
  | gemServer |
  gemServer := super withGemServerDo: block.
  gemServer delegate: delegate.
  self runGemServer: gemServer during: block
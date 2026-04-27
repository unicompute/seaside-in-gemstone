private
withGemServerReader: reader do: block
  | gemServer |
  gemServer := super withGemServerDo: block.
  gemServer reader: reader.
  self runGemServer: gemServer during: block
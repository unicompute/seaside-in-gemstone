private
withGemServerRoute: route do: block
  | gemServer |
  gemServer := super withGemServerDo: block.
  gemServer route: route.
  self runGemServer: gemServer during: block
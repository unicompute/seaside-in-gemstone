private
withGemServerBindingAddress: bindingAddress do: block
  | gemServer |
  gemServer := super withGemServerDo: block.
  gemServer bindingAddress: bindingAddress.
  self runGemServer: gemServer during: block
private
withGemServerAuthenticator: authenticator do: block
  | gemServer |
  gemServer := super withGemServerDo: block.
  gemServer authenticator: authenticator.
  self runGemServer: gemServer during: block
private
withServerAuthenticator: authenticator do: block
  self withGemServerAuthenticator: authenticator do: block
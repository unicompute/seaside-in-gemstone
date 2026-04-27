private
isNativeSSLPluginPresent
  "Return whether the SSL VM plugin can be instanciated and intialized."

  ZdcGemStoneSSLSession new destroy.
  ^ true
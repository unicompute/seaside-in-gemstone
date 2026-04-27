request handling
handleRequestProtected: request
  "Handle request and return a response.
	If a Smalltalk Error is thrown, return a HTTP Server Error response."

  ^ self
    serve: [ self authenticateAndDelegateRequest: request ]
    onError: [ :exception | 
      self gemServer doInteractiveModePass: exception.
      exception return: (ZnResponse serverError: exception printString) ]
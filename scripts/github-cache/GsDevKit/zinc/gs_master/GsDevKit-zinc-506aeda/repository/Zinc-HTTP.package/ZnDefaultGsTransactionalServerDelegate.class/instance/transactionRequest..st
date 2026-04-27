responses
transactionRequest: request
  "Transaction request store into a persistent field ... note that no transaction is needed by handler as the 
   entire request handler is wrapped by a transaction."

  | globalName fieldName fieldValue info entity |
  globalName := request uri queryAt: 'globalName' ifAbsent: [ '' ].
  fieldName := request uri queryAt: 'fieldName' ifAbsent: [ '' ].
  fieldValue := request uri queryAt: 'fieldValue' ifAbsent: [ '' ].
  (UserGlobals at: globalName asSymbol) at: fieldName put: fieldValue.
  info := self generateTransactionRequestString: request.
  entity := ZnEntity textCRLF: info.
  ^ ZnResponse ok: entity
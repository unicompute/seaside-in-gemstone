initialize-release
initialize
  super initialize.
  self
    map: 'transaction' to: #'transactionRequest:';
    yourself
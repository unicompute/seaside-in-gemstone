testing
expectedFailures
  ^ ((System stoneVersionAt: 'gsVersion') beginsWith: '2.')
    ifTrue: [ #(#'testError') ]
    ifFalse: [ #() ]